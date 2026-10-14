from __future__ import print_function
import rospy
import rosbag
import threading
import sys
from sensor_msgs.msg import Image

class MultiTopicRecorder:
  def __init__(self, topics):
    self.bag = rosbag.Bag('calibration_data.bag', 'w')
    self.topics = topics
    self.data = {topic: None for topic in topics}
    self.subscribers = []
    rospy.on_shutdown(self.close)

  def start(self):
    for topic in self.topics:
      sub = rospy.Subscriber(topic, Image, self.callback, callback_args=topic)
      self.subscribers.append(sub)

  def callback(self, msg, topic):
    self.data[topic] = msg

  def record_data(self):
    for topic, msg in self.data.items():
      if msg is not None:
        print("Recording data for {}".format(topic))
        self.bag.write(topic, msg)
      else:
        print("No data available for {}".format(topic))

  def close(self):
    self.bag.close()
    print("Shutting down")

def wait_for_enter(recorder):
  while True:
    input_function("Press Enter to record current frames...")
    recorder.record_data()

if __name__ == '__main__':
  rospy.init_node('multi_topic_recorder', anonymous=True)

  # Check Python version to specify the proper function for input
  if sys.version_info[0] >= 3:
    input_function = input
  else:
    input_function = raw_input

  # List of topics to subscribe to
  topics = [
    "/flir/adk/image_thermal",
    "/flir/blackfly/cam0/image_raw",
    "/mapir_cam/image_raw",
    "/zed2i/zed_node/left/image_rect_color",
    "/zed2i/zed_node/right/image_rect_color"
  ]

  recorder = MultiTopicRecorder(topics)
  recorder.start()

  t = threading.Thread(target=wait_for_enter, args=(recorder,))
  t.daemon = True
  t.start()

  rospy.spin()
