package com.simonellistonball.hadoopsummit16

import kafka.serializer.StringDecoder

import org.apache.spark._
import org.apache.spark.rdd.RDD
import org.apache.spark.streaming._
import org.apache.spark.streaming.kafka._

import org.apache.log4j.Logger

import net.liftweb.json.parse
import net.liftweb.json.DefaultFormats
import net.liftweb.json.MappingException

import org.apache.hadoop.hbase.HBaseConfiguration
import org.apache.hadoop.hbase.client.{HBaseAdmin,HTable,Put,Get}
import org.apache.hadoop.hbase.util.Bytes

object Streaming {
  val logger:Logger = Logger.getLogger(getClass)

  def main(args: Array[String]) {
    if (args.length < 2) {
      System.err.println(s"""
        |Usage: App <brokers> <topics>
        """.stripMargin)
      System.exit(1)
    }
    val Array(brokers, topics) = args
    logger.info(s"Using brokers: ${brokers}")
    logger.info(s"Using topics: ${topics}")

    // setup a streaming context
    val sc = new SparkContext(new SparkConf().setAppName("Tracer"))
    val ssc = new StreamingContext(sc, Seconds(60))

    // create a kafka stream
    val topicsSet = topics.split(",").toSet
    val kafkaParams = Map[String, String](
      "metadata.broker.list" -> brokers,
      "group.id" -> ("sparky-" + java.util.UUID.randomUUID.toString),
      "auto.offset.reset" -> "largest")

    val directKafkaStream = KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder](ssc, kafkaParams, topicsSet)
    val jsonStream = directKafkaStream.map(_._2)

    case class SensorRecord(sensor:String, signalDbm: Double, mac: String, ts_lastseen: Long, ts_firstseen: Long) {
      def compare(that: SensorRecord): Int = this.signalDbm compare that.signalDbm
    }
    //case class SensorTick(sensor:String, signalDb: Double)

    val records = jsonStream
      .filter(x => x.contains('{') && !x.startsWith("wifiMon"))
      .map(x => {
        implicit val formats = DefaultFormats
        try { parse(x).extract[SensorRecord]
        } catch {
          case ex: MappingException => {
            null
          }
          case ex: Throwable => {
            logger.info(x)
            logger.warn(ex)
            null
          }
        }
    }).filter(x => x match {
      case null => false
      case _ => true
    })
    val recordsByMac = records.map(x => (x.mac, x))

    recordsByMac.cache()

    // get the main access point for each mac in this period
    def maxSensor(a: SensorRecord, b: SensorRecord): SensorRecord = if (a.signalDbm > b.signalDbm) a else b

    val maxSignalPerMac = recordsByMac.reduceByKey(maxSensor)

    // write the max signal out to hbase for this time period - note the horrible use of system time. I feel bad.
    maxSignalPerMac.foreachRDD { rdd =>
      rdd.foreachPartition { partitionOfRecords =>
        val hConf = new HBaseConfiguration()
        hConf.set("hbase.zookeeper.quorum", "hs16w05.cloud.hortonworks.com,hs16w06.cloud.hortonworks.com,hs16w07.cloud.hortonworks.com")
        hConf.set("hbase.zookeeper.property.clientPort", "2181")
        hConf.set("zookeeper.znode.parent", "/hbase-unsecure")
        val hTable = new HTable(hConf, "traces")
        partitionOfRecords.foreach(r => {
          val recordPut = new Put(Bytes.toBytes(r._2.mac))
          val time = r._2.ts_lastseen.toString
          val record = r._2.sensor
          logger.info(s"Write HBASE: ${r._2.mac} - ${time}: ${record}")
          recordPut.add("b".getBytes(), Bytes.toBytes(time), record.getBytes())
          hTable.put(recordPut)
        })
      }
    }

    // Start the computation
    ssc.start()
    ssc.awaitTermination()
  }
}
