import numpy as np
import cv2

image = cv2.imread('vidprocessingpy/images.jpeg', cv2.IMREAD_GRAYSCALE)
resize_image = cv2.resize(image,(256,256)).astype(np.int32)
padded_image = np.pad(
    resize_image, 
    pad_width=1,
    mode='constant',
    constant_values=0
)
pixel_stream = padded_image.flatten()

with open('pixel.txt', 'w') as f:
    for p in pixel_stream: 
        f.write(f"{p}\n")

output = []
for i in range(1,257):
    for j in range(1,257):
        pixel00 = padded_image[i-1][j-1]
        pixel01 = padded_image[i-1][j]
        pixel02 = padded_image[i-1][j+1]
        pixel20 = padded_image[i+1][j-1]
        pixel21 = padded_image[i+1][j]
        pixel22 = padded_image[i+1][j+1]
        out = pixel00 * -1 + pixel01 * -2 + pixel02 * -1 + pixel20 + pixel21 * 2 + pixel22
        out = abs(out)
        out = 255 if out > 255 else out
        output.append(out)
with open('expected.txt', 'w') as f:
    for x in output:
        f.write(f"{x}\n")
        
expected_image = np.array(output, dtype=np.uint8).reshape(256, 256)
cv2.imwrite("expected.png", expected_image)

print("Saved expected.png")
print(padded_image.shape)
print(len(pixel_stream))
print(len(output))
