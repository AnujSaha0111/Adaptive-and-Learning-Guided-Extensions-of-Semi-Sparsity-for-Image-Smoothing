import cv2
import numpy as np

# Load noisy image
img = cv2.imread("lena_noisy.png")
# img = cv2.imread("Cameraman_noisy.png")
# img = cv2.imread("Barbara_noisy.png")
# img = cv2.imread("strip_noise.png")

# Convert to grayscale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Canny edges
edges = cv2.Canny(gray, 40, 120)

# Convert to float
edges = edges.astype(np.float32) / 255.0

# Smooth to create soft edge confidence
edges = cv2.GaussianBlur(edges, (11,11), 3)

# Normalize to [0,1]
edges = edges / edges.max()

# Save properly
cv2.imwrite("edges/edge_map_Lena.png", (edges * 255).astype(np.uint8))
# cv2.imwrite("edges/edge_map_Barbara.png", (edges * 255).astype(np.uint8))
# cv2.imwrite("edges/edge_map_Cameraman.png", (edges * 255).astype(np.uint8))
# cv2.imwrite("edges/edge_map_strip_noise.png", (edges * 255).astype(np.uint8))

print("Edge map saved to edges")