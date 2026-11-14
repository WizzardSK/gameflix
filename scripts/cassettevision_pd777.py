# Epoch Cassette Vision games for the PD777 libretro core.
# The only set on archive.org (epoch-cassette-vision-roms-and-emulator) has the
# 11 games compiled into Windows builds of the emulator, plus their rom.cpp
# sources ("CPP Files.zip"). This takes those sources and writes each game as a
# zip of game.bin777 (the code, PD777's formatted format: address/code pairs)
# and game.ptn777 (the 7x7 and 8x7 character patterns and the bent characters).
# The code gives the same ROM image (and so the same checksum, by which the core
# picks the game's controls) as the compiled build. The pattern format stores
# bent characters as one type, so the few drawn with alternating bent types
# draw without the skew.
# usage: cassettevision_pd777.py <dir of .cpp files> <output dir>
import re,sys,os,zipfile
src,out=sys.argv[1],sys.argv[2]
def arr(s,name):
    m=re.search(r'PD777::'+name+r'\[[^\]]*\]\s*=\s*\{(.*?)\};',s,re.S)
    body=re.sub(r'//[^\n]*','',m.group(1)); body=re.sub(r'/\*.*?\*/','',body,flags=re.S)
    body=body.replace('CHAR_BENT1','4').replace('CHAR_BENT2','8')
    return [int(x,0) for x in re.findall(r'0[xX][0-9a-fA-F]+|0[bB][01]+|\d+',body)]
for f in sorted(os.listdir(src)):
    if not f.endswith('.cpp'): continue
    s=open(os.path.join(src,f),encoding='utf-8',errors='replace').read()
    raw=arr(s,'rawRom'); raw+=[0]*(4096-len(raw)); p7=arr(s,'patternRom'); p8=arr(s,'patternRom8'); attr=arr(s,'characterAttribute')
    assert len(raw)==4096 and len(p7)==686 and len(p8)==98 and len(attr)<=256,(f,len(raw),len(p7),len(p8),len(attr))
    # compiled path: rom=0xFFFF, rom[addr]=code
    romA=[0xFFFF]*2048
    for i in range(0,4096,2): romA[raw[i]]=raw[i+1]
    romB=[0xFFFF]*2048
    for i in range(0,4096,2): romB[raw[i]&0x7FF]=raw[i+1]&0xFFF
    assert romA==romB,(f,'code masking differs')
    hdr=bytearray(0x100); hdr[0:20]=b'_CassetteVision_0000'
    t=os.path.splitext(f)[0].encode()[:0xE0]; hdr[0x20:0x20+len(t)]=t
    body=b''.join(int.to_bytes(raw[i],2,'little')+int.to_bytes(raw[i+1],2,'little') for i in range(0,4096,2))
    # bent: attr = (c,0x0C)*7 runs ..., 0xFF,0
    starts=[]; i=0
    while attr[i]!=0xFF:
        c=attr[i]
        for j in range(7): assert attr[i+2*j]==c+j and attr[i+2*j+1] in (4,8),(f,i,j)
        starts.append(c); i+=14
    assert attr[i+1]==0 and len(starts)<=16,(f,starts)
    ph=bytearray(0x30); ph[0:20]=b'*CassetteVision*0000'
    for k,c in enumerate(starts): ph[0x20+k]=c
    for k in range(len(starts),16): ph[0x20+k]=0xFF
    ptn=bytes(ph)+bytes(p7)+bytes(p8); ptn+=bytes(0x340-len(ptn)); assert len(ptn)==0x340
    name=os.path.splitext(f)[0]
    with zipfile.ZipFile(os.path.join(out,name+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr(name+'.bin777',bytes(hdr)+body); z.writestr(name+'.ptn777',ptn)
    print(name,'bent',starts,'checksum',sum(romA)&0xFFFFFFFF)
