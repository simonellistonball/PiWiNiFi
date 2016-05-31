name := "streaming"

version := "1.0"
scalaVersion := "2.10.5"
val sparkVersion = "1.5.2.2.3.4.0-3485"
//val kafkaVersion = "0.9.0.2.3.4.0-3485"
val hbaseVersion = "1.1.2.2.4.0.0-169"
val hadoopVersion = "2.7.1.2.3.4.0-3485"

libraryDependencies += "org.apache.spark" % "spark-streaming_2.10" % sparkVersion % "provided"
libraryDependencies ++= Seq(("org.apache.spark" %% "spark-streaming-kafka" % sparkVersion).
  exclude("org.spark-project.spark", "unused"))

// general utilities
libraryDependencies += "log4j" % "log4j" % "1.2.14" % "provided"
libraryDependencies += "net.liftweb" %% "lift-json" % "2.6.3"

libraryDependencies ++= Seq(
  "org.apache.hbase" % "hbase" % hbaseVersion,
  "org.apache.hbase" % "hbase-common" % hbaseVersion,
  "org.apache.hbase" % "hbase-client" % hbaseVersion,
  "org.apache.hadoop" % "hadoop-common" % hadoopVersion % "provided",
  "org.apache.hadoop" % "hadoop-client" % hadoopVersion % "provided"
)


resolvers += "Local Maven Repository" at "file://"+Path.userHome.absolutePath+"/.m2/repository"
resolvers += "hdp-private" at "http://nexus-private.hortonworks.com/nexus/content/groups/public"
resolvers += "spring-releases" at "https://repo.spring.io/libs-release"
resolvers += Resolver.sonatypeRepo("public")
resolvers += DefaultMavenRepository


mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
  {
    case x if x.startsWith("META-INF/ECLIPSEF.RSA") => MergeStrategy.last
    case x if x.startsWith("META-INF/mailcap") => MergeStrategy.last
    case x if x.startsWith("plugin.properties") => MergeStrategy.last
    case x if x.startsWith("logback.xml") => MergeStrategy.first
    case x => old(x)
  }
}

assemblyOption in assembly ~= { _.copy(includeScala = false) }
