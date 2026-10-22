"""Sinh icon app Dat Bike — xe máy điện + tia sét.

Vẽ ở 4096 rồi downscale về 1024 (antialias). Xuất:
  assets/icon/icon.png            — full-bleed 1024 (legacy launcher)
  assets/icon/icon_foreground.png — 1024 trong suốt, xe scale ~62% (adaptive icon)
"""
from PIL import Image, ImageDraw
import math

S = 4096          # canvas vẽ
OUT = 1024        # xuất

GREEN_DARK = (27, 94, 32)     # #1B5E20
GREEN = (46, 125, 50)         # #2E7D32
WHITE = (255, 255, 255)
YELLOW = (255, 214, 0)        # #FFD600

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# ---------- nền bo góc ----------
R = int(S * 0.185)
d.rounded_rectangle([0, 0, S - 1, S - 1], radius=R, fill=GREEN_DARK + (255,))

# gradient nhẹ: lớp sáng hơn phía trên (chồng rounded rect alpha thấp)
grad = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(grad)
for y in range(S):
    a = int(46 * max(0.0, 1.0 - y / S))          # sáng dần về trên
    gd.line([(0, y), (S, y)], fill=WHITE + (a,))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=R, fill=255)
img.paste(grad, (0, 0), Image.composite(grad.split()[3], Image.new("L", (S, S), 0), mask))

# viền mảnh
d = ImageDraw.Draw(img)
d.rounded_rectangle([int(S*0.012), int(S*0.012), S - int(S*0.012) - 1, S - int(S*0.012) - 1],
                    radius=int(R * 0.96), outline=(255, 255, 255, 28), width=int(S * 0.008))

# ---------- xe máy điện (silhouette trắng, nhìn ngang, hướng phải) ----------
def circle(cx, cy, r, fill=None, outline=None, w=0):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline, width=w)

def poly(pts, fill):
    d.polygon(pts, fill=fill)

def rrect(box, rad, fill):
    d.rounded_rectangle(box, radius=rad, fill=fill)

W = S * 0.09375     # 384 @4096 → scale trực tiếp
bike = Image.new("RGBA", (S, S), (0, 0, 0, 0))
bd = ImageDraw.Draw(bike)

# bánh xe: vành trắng dày + moay-ơ
def wheel(cx, cy, r):
    bd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE + (255,), width=int(S * 0.032))
    bd.ellipse([cx - r * 0.30, cy - r * 0.30, cx + r * 0.30, cy + r * 0.30], fill=WHITE + (255,))

wr = S * 0.108           # bán kính bánh
wheel(S * 0.285, S * 0.700, wr)   # bánh sau
wheel(S * 0.760, S * 0.700, wr)   # bánh trước

# thân xe: khối chính (swoosh) nối qua 2 bánh
body = [
    (S*0.170, S*0.660), (S*0.185, S*0.545), (S*0.250, S*0.480), (S*0.365, S*0.455),
    (S*0.470, S*0.470), (S*0.560, S*0.500), (S*0.640, S*0.520), (S*0.720, S*0.540),
    (S*0.845, S*0.585), (S*0.870, S*0.660), (S*0.845, S*0.700), (S*0.170, S*0.700),
]
poly(body, WHITE + (255,))

# cột lái trước + tay lái
poly([(S*0.690, S*0.560), (S*0.760, S*0.395), (S*0.805, S*0.415), (S*0.755, S*0.590)], WHITE + (255,))
# tay lái (thanh nghiêng + 2 đầu tròn)
bd.line([(S*0.735, S*0.400), (S*0.865, S*0.355)], fill=WHITE + (255,), width=int(S * 0.030))
circle(S*0.735, S*0.400, S*0.022, fill=WHITE + (255,))
circle(S*0.865, S*0.355, S*0.026, fill=WHITE + (255,))
# đèn pha
circle(S*0.875, S*0.395, S*0.020, fill=YELLOW + (255,))

# yên xe
rrect([S*0.235, S*0.425, S*0.430, S*0.478], S*0.026, WHITE + (255,))

# chân chống/đế nối bánh sau xuống thân
poly([(S*0.300, S*0.700), (S*0.330, S*0.620), (S*0.380, S*0.620), (S*0.380, S*0.700)], WHITE + (255,))
poly([(S*0.680, S*0.700), (S*0.700, S*0.610), (S*0.745, S*0.610), (S*0.760, S*0.700)], WHITE + (255,))

# ---------- tia sét vàng trên thân ----------
bolt = [
    (S*0.520, S*0.405), (S*0.395, S*0.585), (S*0.470, S*0.585),
    (S*0.425, S*0.760), (S*0.585, S*0.545), (S*0.505, S*0.545), (S*0.575, S*0.405),
]
# viền tối mảnh cho bolt nổi trên thân trắng
bd.polygon([(x + S*0.010, y) for x, y in bolt], fill=GREEN_DARK + (255,))
bd.polygon(bolt, fill=YELLOW + (255,))

# ---------- composje: bike lên nền ----------
img.alpha_composite(bike)

# ---------- xuất ----------
final = img.resize((OUT, OUT), Image.LANCZOS)
import os
os.makedirs(r"D:\CuaMan\dat-bike\datbike_app\assets\icon", exist_ok=True)
final.convert("RGB").save(r"D:\CuaMan\dat-bike\datbike_app\assets\icon\icon.png")

# adaptive foreground: xe thu nhỏ ~62%, nền trong suốt
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
scaled = bike.resize((int(S * 0.62), int(S * 0.62)), Image.LANCZOS)
fg.alpha_composite(scaled, (int(S * 0.19), int(S * 0.19)))
fg.resize((OUT, OUT), Image.LANCZOS).save(r"D:\CuaMan\dat-bike\datbike_app\assets\icon\icon_foreground.png")

print("done:", OUT, "px")
