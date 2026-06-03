import uharfbuzz as hb, freetype, numpy as np
from PIL import Image, ImageFilter
from fontTools.ttLib import TTFont
DEFAULT_FONT="fatemimaqala-googlefonts/fonts/FatemiMaqala-Regular.ttf"

class Det:
    def __init__(self, font):
        self.tt=TTFont(font); self.UPM=self.tt['head'].unitsPerEm
        self.order=self.tt.getGlyphOrder(); n2g={n:i for i,n in enumerate(self.order)}
        self.marks=set()
        gd=self.tt['GDEF'].table.GlyphClassDef
        if gd:
            for g,c in gd.classDefs.items():
                if c==3: self.marks.add(n2g[g])
        self.data=open(font,'rb').read(); self.face=hb.Face(self.data)
    def collisions(self, text, px=600, margin_units=35, min_pixels=4):
        fnt=hb.Font(self.face); fnt.scale=(self.UPM,self.UPM)
        buf=hb.Buffer(); buf.add_str(text); buf.guess_segment_properties(); hb.shape(fnt,buf,{})
        ft=freetype.Face_no=None
        ft=freetype.Face(DEFAULT_FONT) if False else freetype.Face(self._fp())
        ft.set_char_size(int(px*64)); sc=px/self.UPM
        k=max(1,int(round(margin_units*px/self.UPM)))
        glyphs=[]; penx=0.0; base_y=px*2.0
        for i,p in zip(buf.glyph_infos,buf.glyph_positions):
            ft.load_glyph(i.codepoint, freetype.FT_LOAD_RENDER); b=ft.glyph.bitmap; w,h=b.width,b.rows
            x=penx+p.x_offset*sc+ft.glyph.bitmap_left; y=base_y-p.y_offset*sc-ft.glyph.bitmap_top
            if w and h:
                mask=np.frombuffer(bytes(b.buffer),dtype=np.uint8).reshape(h,w)>40
            else: mask=np.zeros((0,0),bool)
            glyphs.append(dict(gid=i.codepoint,cl=i.cluster,x=int(round(x)),y=int(round(y)),w=w,h=h,
                               mask=mask,ismark=i.codepoint in self.marks))
            penx+=p.x_advance*sc
        hits=[]
        for m in glyphs:
            if not m['ismark'] or m['w']==0: continue
            # grow mark mask by k (near-miss margin)
            gm=Image.fromarray((m['mask']*255).astype('uint8'))
            gm=gm.crop((-k,-k,m['w']+k,m['h']+k)).filter(ImageFilter.MaxFilter(2*k+1))
            gmask=np.array(gm)>0; gx,gy=m['x']-k,m['y']-k; gh,gw=gmask.shape
            for o in glyphs:
                if o is m or o['w']==0 or o['cl']==m['cl']: continue
                ox0=max(gx,o['x']); oy0=max(gy,o['y']); ox1=min(gx+gw,o['x']+o['w']); oy1=min(gy+gh,o['y']+o['h'])
                if ox1<=ox0 or oy1<=oy0: continue
                mm=gmask[oy0-gy:oy1-gy, ox0-gx:ox1-gx]
                oo=o['mask'][oy0-o['y']:oy1-o['y'], ox0-o['x']:ox1-o['x']]
                inter=np.logical_and(mm,oo).sum()
                if inter>=min_pixels: hits.append((m['gid'],o['gid'],int(inter)))
        return hits
    def _fp(self):
        if not hasattr(self,'_fpath'):
            import tempfile; self._fpath=tempfile.mktemp(suffix=".ttf"); open(self._fpath,'wb').write(self.data)
        return self._fpath

_d=Det(DEFAULT_FONT)
def collisions(text, **kw): return _d.collisions(text, **kw)
def names(): return _d.order
