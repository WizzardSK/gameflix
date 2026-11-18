# mkthumbs.py ART OUT (python3 scripts/mkthumbs.py art art/thumbs, needs Pillow): main-page pictures, 320x240: the device's cut-out (art/consoles), trimmed and as big as
# fits (full width or full height, a small margin), on a coloured glow fading to black - the colour
# taken from the platform's art/background picture, so each keeps its colour. Logos and text
# instead of a device keep their background picture.
import os,sys,colorsys
from PIL import Image, ImageDraw, ImageFilter
SRC,OUT=sys.argv[1],sys.argv[2]; os.makedirs(OUT,exist_ok=True)
KEEP={'chailove','scummvm','vircon32','wasm4','rx78','lindbergh','vaporspec','tic80','voxatron'}
W,H=320,240
def glow_colour(bg):
    im=Image.open(bg).convert('RGB').resize((64,36)); px=list(im.getdata())
    best=[]
    for r,g,b in px:
        h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
        if v>0.12: best.append((s*v,(r,g,b)))
    best.sort(reverse=True); top=[c for _,c in best[:len(best)//6 or 1]]
    if not top: return (70,70,70)
    r,g,b=[sum(c[i] for c in top)/len(top) for i in range(3)]
    h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
    r,g,b=colorsys.hsv_to_rgb(h,min(1,max(0.55,s)),max(0.7,min(0.95,v)))
    return (int(r*255),int(g*255),int(b*255))
def glow(c):
    # radial: the colour in the middle, black at the corners
    small=Image.new('RGB',(64,48)); p=small.load()
    for y in range(48):
        for x in range(64):
            d=(((x-31.5)/40)**2+((y-23.5)/32)**2)**0.5; k=max(0,1-d)**0.9
            p[x,y]=tuple(int(v*k) for v in c)
    return small.resize((W,H),Image.BICUBIC)
for f in sorted(os.listdir(SRC+'/background')):
    if not f.endswith('.jpg'): continue
    n=f[:-4]; cp=f'{SRC}/consoles/{n}.png'
    if n in KEEP or not os.path.exists(cp):
        im=Image.open(f'{SRC}/background/{f}').convert('RGB'); im=im.resize((W,int(im.height*W/im.width))) if im.width/im.height>W/H else im.resize((int(im.width*H/im.height),H))
        o=Image.new('RGB',(W,H)); o.paste(im,((W-im.width)//2,(H-im.height)//2)); o.save(f'{OUT}/{n}.jpg',quality=88); continue
    dev=Image.open(cp).convert('RGBA'); a=dev.split()[3].point(lambda v:255 if v>16 else 0); bb=a.getbbox()
    if bb: dev=dev.crop(bb)
    m=0.06; s=min(W*(1-2*m)/dev.width,H*(1-2*m)/dev.height); dev=dev.resize((max(1,round(dev.width*s)),max(1,round(dev.height*s))),Image.LANCZOS)
    o=glow(glow_colour(f'{SRC}/background/{f}'))
    x,y=(W-dev.width)//2,(H-dev.height)//2
    sh=Image.new('L',(W,H),0); sh.paste(dev.split()[3],(x+4,y+6)); sh=sh.filter(ImageFilter.GaussianBlur(6)).point(lambda v:int(v*0.6))
    o.paste((0,0,0),(0,0),sh); o.paste(dev,(x,y),dev); o.save(f'{OUT}/{n}.jpg',quality=88)
