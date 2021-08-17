#define __gm82chunk_init
/*        
    Game Maker 8.2 room chunk system
    renex, august 2021
    
    acknowledgements:
    Floogle - hook & compiler technology
    BPzeBanshee - initial proof of concept
*/
var m,c,i;

global.__gm82chunk_id[0]=room_add()
global.__gm82chunk_id[1]=room_add()
global.__gm82chunk_curid=0

//lookup tables
m=ds_map_create()
c=background_create_color(1,1,0) background_delete(c)
for (i=0;i<c;i+=1) {
    if (background_exists(i)) ds_map_add(m,background_get_name(i),i)
}         
ds_map_add(m,"",-1)
global.__gm82chunk_bgmap=m

m=ds_map_create()
c=object_add() object_delete(c)
for (i=0;i<c;i+=1) {
    if (object_exists(i)) ds_map_add(m,object_get_name(i),i)
}         
ds_map_add(m,"",-1)
global.__gm82chunk_objmap=m


#define chunk_load_room
///chunk_load_room(directory):roomid
//loads a room file into an unloaded room and returns it
var rm,dir,bgmap,objmap,i,f,f2,str,roomcode;

dir=string(argument0)
if (!directory_exists(dir)) {
    show_error("gm82chunk tried loading nonexisting room: "+dir,1)
    return 0
}

dir+="\"
bgmap=global.__gm82chunk_bgmap
objmap=global.__gm82chunk_objmap
                    
global.__gm82chunk_curid=!global.__gm82chunk_curid
rm=global.__gm82chunk_id[global.__gm82chunk_curid]

room_tile_clear(rm)
room_instance_clear(rm)

//room.txt
map=ds_map_create()
ds_map_read_ini(map,dir+"room.txt")
                 
room_set_caption(rm,ds_map_find_value(map,"caption"))
roomwidth=real(ds_map_find_value(map,"width")) room_set_width(rm,roomwidth)
roomheight=real(ds_map_find_value(map,"height")) room_set_height(rm,roomheight)
room_set_background_color(rm,real(ds_map_find_value(map,"bg_color")),real(ds_map_find_value(map,"clear_screen")))
room_set_view_enabled(rm,real(ds_map_find_value(map,"views_enabled")))
roomcode="room_speed="+ds_map_find_value(map,"roomspeed")+" "

//backgrounds and views
var bg,ii;
for (i=0;i<8;i+=1) {
    ii=string(i)
    if (ds_map_find_value(map,"bg_visible"+ii)=="1") {
        bg=ds_map_find_value(bgmap,ds_map_find_value(map,"bg_source"+ii))
        if (bg!=-1) {
            room_set_background(rm,i,1,
                real(ds_map_find_value(map,"bg_is_foreground"+ii)),
                bg,
                real(ds_map_find_value(map,"bg_xoffset"+ii)),
                real(ds_map_find_value(map,"bg_yoffset"+ii)),
                real(ds_map_find_value(map,"bg_tile_h"+ii)),
                real(ds_map_find_value(map,"bg_tile_v"+ii)),
                real(ds_map_find_value(map,"bg_hspeed"+ii)),
                real(ds_map_find_value(map,"bg_vspeed"+ii)),
                1    
            )
            if (ds_map_find_value(map,"bg_stretch"+ii)="1") {
                roomcode+="background_xscale["+ii+"]="+string(roomwidth/background_get_width(bg))
                        +" background_yscale["+ii+"]="+string(roomheight/background_get_height(bg))+" "
            }
        }
    }
    
    if (ds_map_find_value(map,"view_visible"+ii)=="1") {
        room_set_view(rm,i,1,
            real(ds_map_find_value(map,"view_xview"+ii)),
            real(ds_map_find_value(map,"view_yview"+ii)),
            real(ds_map_find_value(map,"view_wview"+ii)),
            real(ds_map_find_value(map,"view_hview"+ii)),
            real(ds_map_find_value(map,"view_xport"+ii)),
            real(ds_map_find_value(map,"view_yport"+ii)),
            real(ds_map_find_value(map,"view_wport"+ii)),
            real(ds_map_find_value(map,"view_hport"+ii)),
            real(ds_map_find_value(map,"view_fol_hbord"+ii)),
            real(ds_map_find_value(map,"view_fol_vbord"+ii)),
            real(ds_map_find_value(map,"view_fol_hspeed"+ii)),
            real(ds_map_find_value(map,"view_fol_vspeed"+ii)),
            ds_map_find_value(objmap,ds_map_find_value(objmap,"view_fol_target"+ii))
        )
    }
}

//instances.txt
var iobj,ix,iy,icode,ixs,iys,iblend,iangle,iid;
f=file_text_open_read(dir+"instances.txt") while (!file_text_eof(f)) {str=file_text_read_string(f) file_text_readln(f)
                               p=string_pos(",",str) iobj=ds_map_find_value(objmap,string_copy(str,1,p-1))
    str=string_delete(str,1,p) p=string_pos(",",str) ix=real(string_copy(str,1,p-1))
    str=string_delete(str,1,p) p=string_pos(",",str) iy=real(string_copy(str,1,p-1))
    str=string_delete(str,1,p) p=string_pos(",",str) icode=string_copy(str,1,p-1)
    str=string_delete(str,1,p) p=string_pos(",",str) //locked
    str=string_delete(str,1,p) p=string_pos(",",str) ixs=string_copy(str,1,p-1)
    str=string_delete(str,1,p) p=string_pos(",",str) iys=string_copy(str,1,p-1)
    str=string_delete(str,1,p) p=string_pos(",",str) iblend=string_copy(str,1,p-1)
    str=string_delete(str,1,p)                       iangle=str
    
    str=""
    if (ixs!="1") str+="image_xscale="+ixs+" "
    if (iys!="1") str+="image_yscale="+iys+" "
    if (iblend!="4294967295") {
        iblend=real(iblend)
        str+="image_blend="+string(iblend&$ffffff)+" image_alpha="+string(floor(iblend/$1000000)/$ff)+" "
    }
    if (iangle!="0") str+="image_angle="+iangle+" "
    if (icode!="") str+=file_text_read_all(dir+icode+".gml")
            
    iid=room_instance_add(rm,ix,iy,iobj)
    if (str!="") roomcode+="with("+string(iid)+"){"+str+"} "
} file_text_close(f)

//layers.txt
var layer,tbg,tx,ty,tu,tv,tw,th,tsx,tsy,tblend;
f=file_text_open_read(dir+"layers.txt") while (!file_text_eof(f)) {str=file_text_read_string(f) file_text_readln(f)
    layer=real(str)
    f2=file_text_open_read(dir+str+".txt") while (!file_text_eof(f2)) {str=file_text_read_string(f2) file_text_readln(f2)
                                   p=string_pos(",",str) tbg=ds_map_find_value(bgmap,string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) tx=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) ty=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) tu=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) tv=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) tw=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) th=real(string_copy(str,1,p-1))
        str=string_delete(str,1,p) p=string_pos(",",str) //locked
        str=string_delete(str,1,p) p=string_pos(",",str) tsx=string_copy(str,1,p-1)
        str=string_delete(str,1,p) p=string_pos(",",str) tsy=string_copy(str,1,p-1)
        str=string_delete(str,1,p)                       tblend=str
        
        if (tblend!="4294967295" || tsx!="1" || tsy!="1") {   
            tsx=real(tsx)
            tsy=real(tsy)
            if (tblend!="4294967295") {
                tblend=real(tblend)                                                                                                            
                roomcode+="tile_set_blend("+string(room_tile_add_ext(rm,tbg,tu,tv,tw,th,tx,ty,layer,tsx,tsy,string(floor(tblend/$1000000)/$ff)))+","+string(tblend&$ffffff)+") "
            } else room_tile_add_ext(rm,tbg,tu,tv,tw,th,tx,ty,layer,tsx,tsy,1)
        } else room_tile_add(rm,tbg,tu,tv,tw,th,tx,ty,layer)
    } file_text_close(f2)
} file_text_close(f)

//code.txt
room_set_code(rm,roomcode+file_text_read_all(dir+"code.gml"))

return rm


#define chunk_load_chunk
///(filename,x,y,scale)

var l,b,count,find,fn,i,ox,oy,scale,bgmap,objmap,code,instq;

fn=argument0
ox=argument1
oy=argument2
scale=argument3

if (fn!="") {
    bgmap=global.__gm82chunk_bgmap
    objmap=global.__gm82chunk_objmap

    b=buffer_create()
    buffer_load(b,fn)
    
    buffer_inflate(b)
    
    if (buffer_read_u8(b)>1) {
        show_error("Chunk file version is too new. Please download an updated version of gm82chunk to load this chunk file.",0)
        exit
    }
    
    buffer_read_string(b) //skip game name - i'll assume you know what you're doing!
    
    repeat (buffer_read_u16(b)) {
        find=ds_map_find_value(bgmap,buffer_read_string(b))    
        repeat (buffer_read_u16(b)) {
            i=tile_add(find,buffer_read_u32(b),buffer_read_u32(b),buffer_read_u32(b),buffer_read_u32(b),ox+buffer_read_i32(b)*scale,oy+buffer_read_i32(b)*scale,buffer_read_i32(b))
            tile_set_scale(i,buffer_read_float(b)*scale,buffer_read_float(b)*scale)
            tile_set_alpha(i,buffer_read_u8(b)/$ff)
            tile_set_blend(i,$10000*buffer_read_u8(b)+$100*buffer_read_u8(b)+buffer_read_u8(b))
        }
    }

    instq=ds_queue_create()
    repeat (buffer_read_u16(b)) {
        find=ds_map_find_value(objmap,buffer_read_string(b))    
        repeat (buffer_read_u16(b)) {
            with (instance_create(ox,oy,find)) {
                x+=buffer_read_i32(b)*scale
                y+=buffer_read_i32(b)*scale
                image_xscale=buffer_read_float(b)*scale
                image_yscale=buffer_read_float(b)*scale
                image_angle=buffer_read_float(b)
                image_alpha=buffer_read_u8(b)/$ff
                image_blend=$10000*buffer_read_u8(b)+$100*buffer_read_u8(b)+buffer_read_u8(b)
                code=buffer_read_string(b)
                if (code!="") ds_queue_enqueue(instq,id)
            }
        }
    }
    repeat (ds_queue_size(instq)) with (ds_queue_dequeue(instq)) {
        execute_string(code)
        speed*=scale
        path_speed*=scale
    }
    ds_queue_destroy(instq)
    
    buffer_destroy(b)
}

