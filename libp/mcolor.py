# Mix colors by averaging, colors are strings of the form #0099ff
def color_mix(*colors):
  final = [0, 0, 0]
  for color in colors:
    r, g, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)
    final = [final[0]+r, final[1]+g, final[2]+b]
  final = [int(float(f)/len(colors)) for f in final]
  # final = [min(255, final[0]), min(255, final[1]), min(255, final[2])]
  return "#%02x%02x%02x" % (final[0], final[1], final[2])
