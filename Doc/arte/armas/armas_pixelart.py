from PIL import Image
P={'.':(0,0,0,0),'k':(0,0,0,255),'d':(52,48,44,255),'m':(114,109,103,255),'l':(177,168,161,255),
   'w':(232,226,220,255),'b':(84,52,34,255),'o':(140,92,56,255),'g':(206,160,64,255)}
ART={
'pistol':[
".kkkkkkkkkkkk",
"kwllllllllllk",
"kmmmmmmmmmmmk",
"kdddddkkkkkk.",
".kmdkdk......",
".kmdkkk......",
"kmdk.........",
"kmdk.........",
"kkkk........."],
'magnum':[
"..kk.............",
".kddkkkkkk.......",
".kmmklllllkkkkkkk",
".kmmkmmmmmwlllllk",
".kdmkmmmmmdmmmmmk",
".kdkkdddddkkkkkk.",
"kobkdk.kk........",
"kobkkk...........",
"kobk.............",
".kkk............."],
'smg':[
"..........k.....",
"kkkkkkkkkkdkkk..",
"kdmwllllllllllkk",
"kdmmmmmmmmmmmmmk",
"kddddddddddkkkk.",
".kkmdkdk.kmk....",
"...kmdkk.kmk....",
"...kmdk..kmk....",
"...kkkk..kdk....",
".........kkk...."],
'shotgun':[
"kkk......................",
"kook.....................",
"kooook"+"k"*19,
".kbooookmwlllllllllllllllk"[:0]+".kboookmwlllllllllllllllk",
"..kbbbk"+"m"*17+"k",
"...kbbkdkk"+"kooooooook"+"kkkk.",
"....kkkdk."+"kkkkkkkkkk"+".....",
".......kk................"],
}
def mk(n):
    a=ART[n]; w=max(len(r) for r in a); im=Image.new('RGBA',(w,len(a)))
    for y,r in enumerate(a):
        for x,c in enumerate(r): im.putpixel((x,y),P[c])
    return im
if __name__=='__main__':
    import sys
    rac=Image.open('/mnt/user-data/uploads/Racoon-Rumble/sprites/spr_player_run/71941fd6-63d6-4dea-8778-56476c77f146.png').convert('RGBA')
    S=8; out=Image.new('RGBA',(5*40*S,40*S),(90,140,90,255))
    for i,n in enumerate(['pistol','magnum','smg','shotgun']):
        g=mk(n); fr=Image.new('RGBA',(40,40)); fr.alpha_composite(rac,(0,4))
        fr.alpha_composite(g,(18,17)); out.alpha_composite(fr.resize((320,320),Image.NEAREST),(i*330,0))
        print(n,g.size)
    out.save('prev.png')
