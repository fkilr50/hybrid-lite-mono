import rosbag
import rospy
import argparse
from cv_bridge import CvBridge

def main():
    parser = argparse.ArgumentParser("invert color for certain topic")
    parser.add_argument("input_bag", help="input bag")
    parser.add_argument("topic", help="topic")
    parser.add_argument("output_bag", help="output bag")

    args = parser.parse_args()

    input_bag = rosbag.Bag(args.input_bag, 'r')
    output_bag = rosbag.Bag(args.output_bag, 'w')
    bridge = CvBridge()

    for topic, msg, t in input_bag.read_messages():
        if(topic == args.topic):
            image = bridge.imgmsg_to_cv2(msg, "mono8")
            image = 255 - image
            msg2 = bridge.cv2_to_imgmsg(image, "mono8")
            msg2.header = msg.header
            msg = msg2
        output_bag.write(topic, msg, t)
    
    output_bag.close()


if __name__ == "__main__":
    main()
