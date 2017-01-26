import boto3
import zlib

def get_file_chunk(dict):
  s3 = boto3.client('s3')
  chunk = s3.get_object( Bucket=dict['Bucket'], Key=dict['Key'], Range="bytes=0-" + '{}'.format(dict['RowSize']) )['Body'].read()
  dec = zlib.decompressobj(32 + zlib.MAX_WBITS)  # offset 32 to skip the header
  return dec.decompress( chunk )

# Make sure that the line delimiter is found within the chunk
def get_line(dict):
  chunk = get_file_chunk(dict)
  if len( chunk.split(dict['LineDelimiter']) ) == 1:
    return None
  else:
    return chunk.split(dict['LineDelimiter'])[0]

def key(dict):
  s3 = boto3.client('s3')
  resp = s3.list_objects_v2( Bucket=dict['Bucket'], Prefix=dict['Prefix'] )
  if resp['KeyCount'] == 0: raise Exception("The target s3://{}/{} does not exist!".format( dict['Bucket'], dict['Prefix'] ))
  return resp['Contents'][0]['Key']

def number_of_columns(event, context):
  if 'RowSize' not in event: event['RowSize'] = 5000
  event['Key'] = key(event)
  print "Got these input paramters {}".format( event )
  while True:
    event['RowSize'] *= 2
    print "Working with RowSize = {}".format( event['RowSize'] )
    if get_line(event) is not None:
      return len( get_line(event).split(event['FieldDelimiter']) )



event = {'LineDelimiter': "\n", 'FieldDelimiter': "\t", 'Bucket': 'narp-archive', 'Prefix': "out_file_9.txt"}
print "number of columns is " + '{}'.format( number_of_columns(event, None) )
