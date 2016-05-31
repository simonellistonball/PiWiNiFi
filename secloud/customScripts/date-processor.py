import json
import java.io
from org.apache.commons.io import IOUtils
from java.nio.charset import StandardCharsets
from org.apache.nifi.processor.io import StreamCallback
import datetime

def time_to_date(time):
    try:
        return datetime.datetime.fromtimestamp(time).strftime('%Y-%m-%dT%H:%M:%S')
    except:
        return None

class PyStreamCallback(StreamCallback):
  def __init__(self):
        pass

  def process(self, inputStream, outputStream):
    text = IOUtils.toString(inputStream, StandardCharsets.UTF_8)
    obj = json.loads(text)
    newObj = obj

    if 'ts_lastlog' in obj:
        newObj['ts_lastlog'] = time_to_date(obj['ts_lastlog'])
    if 'ts_lastseen' in obj:
        newObj['ts_lastseen'] = time_to_date(obj['ts_lastseen'])
    if 'ts_firstseen' in obj:
        newObj['ts_firstseen'] = time_to_date(obj['ts_firstseen'])

    outputStream.write(bytearray(json.dumps(newObj).encode('utf-8')))

flowFile = session.get()
if (flowFile != None):
  flowFile = session.write(flowFile,PyStreamCallback())
  flowFile = session.putAttribute(flowFile, "filename", flowFile.getAttribute('filename').split('.')[0]+'_translated.json')
  session.transfer(flowFile, REL_SUCCESS)
