import numpy as np 
import cv2 

with open("output.txt", "r") as f:
    output = [int(x) for x in f]

output = np.array(output, dtype=np.uint8)
output = output.reshape(256,256) 

cv2.imwrite("verilog_output.png", output)
print("outputted image")

expected = cv2.imread("expected.png", cv2.IMREAD_GRAYSCALE)
verilog = cv2.imread("verilog_output.png", cv2.IMREAD_GRAYSCALE)

diff = cv2.absdiff(expected, verilog)

print("Maximum difference:", diff.max())
print("Total different pixels:", np.count_nonzero(diff))
