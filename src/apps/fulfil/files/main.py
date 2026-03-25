import image, network, math, rpc, sensor, struct, tf, time, mutex, pyb, micropython, omv
from pyb import LED

# Compatibility shim: newer firmware removed rpc_usb_vcp_* helpers.
# Keep existing app/SOM RPC API by providing a USB VCP transport wrapper.
if (not hasattr(rpc, "rpc_usb_vcp_slave")) and hasattr(rpc, "rpc_slave"):
    class _RPCUsbVCPSlaveCompat(rpc.rpc_slave):
        def __init__(self):
            self._vcp = pyb.USB_VCP()
            rpc.rpc_slave.__init__(self)

        def _flush(self):
            while self._vcp.any():
                self._vcp.read()

        def get_bytes(self, buff, timeout_ms):
            start = pyb.millis()
            i = 0
            l = len(buff)
            while l:
                n = self._vcp.any()
                if n:
                    data = self._vcp.read(min(l, n))
                    if data:
                        dlen = len(data)
                        buff[i:i + dlen] = data
                        i += dlen
                        l -= dlen
                        continue
                if (pyb.millis() - start) >= timeout_ms:
                    return None
            return buff

        def put_bytes(self, data, timeout_ms):
            start = pyb.millis()
            i = 0
            l = len(data)
            while i < l:
                n = self._vcp.write(data[i:])
                if n is None:
                    n = 0
                if n > 0:
                    i += n
                    continue
                if (pyb.millis() - start) >= timeout_ms:
                    raise OSError("USB VCP write timeout")

    rpc.rpc_usb_vcp_slave = _RPCUsbVCPSlaveCompat

class Tag:
    def __init__(self):
        self.tag_dst = struct.pack("<HHHH", 0, 0, 0, 0)
        self.tag_sent = True
        self.tag_ready = False
        self.tag_time = pyb.millis()
        self.mutex = mutex.Mutex()
    def is_stale(self):
        # less then 4hz polling
        stale = (pyb.millis() - self.tag_time > 250)
        if stale:
            if self.mutex.test():
                LED(2).off()
                self.tag_ready = False
                self.tag_sent = True
                if not VCP:
                    print("Tag became stale:[cx=%d, cy=%d, id=%d, rot=%d]" \
                             % struct.unpack("<HHHH", self.tag_dst))
                self.mutex.release()
            else:
                if not VCP:
                    print("tag is stale but mutex is locked")
                else:
                    pass
        return stale
micropython.alloc_emergency_exception_buf(100)
#Set false to debug
VCP = True

sensor.reset()
sensor.set_pixformat(sensor.GRAYSCALE)
sensor.set_framesize(sensor.B128X128)
sensor.skip_frames(time = 2000)

image_count=0
clock = time.clock()

#GLOBALS Don't edit w/o mutex once ISR and main loop run
if VCP:
    interface = rpc.rpc_usb_vcp_slave()
else:
    interface = rpc.rpc_uart_slave()

tags = [Tag(), Tag()]
ping = True #for selecting which ping-pong buffer to use

################################################################
# Call Backs
################################################################

# saving images w/o an sd card installed will brick the openmv system
# generally too slow to use in any of our loops
# data is unused
def saveImage(data):
    global image_count
    fname=str(image_count)+".jpg"
    sensor.get_fb().save(fname)

    image_count += 1
    if image_count > 999:
        image_count = 0
start = pyb.millis()

def _tag_value(tag, name):
    value = getattr(tag, name)
    if callable(value):
        return value()
    return value

def _pack_tag(tag):
    cx = int(_tag_value(tag, "cx")) & 0xFFFF
    cy = int(_tag_value(tag, "cy")) & 0xFFFF
    tag_id = int(_tag_value(tag, "id")) & 0xFFFF
    rot = _tag_value(tag, "rotation")
    if abs(rot) <= (2 * math.pi + 0.1):
        rot = math.degrees(rot)
    rot_u16 = int(rot) % 360
    return struct.pack("<HHHH", cx, cy, tag_id, rot_u16)

def ISRCallback(data):
    global start
    global ping
    global tags

    buff_idx = 1
    if ping:
        buff_idx=0
    else: #pong
        buff_idx=1
    #LED(1).on()
    clock.tick()
    tags_found = sensor.snapshot().find_apriltags()
    #LED(1).off()
    if not VCP:
        print("tag fps: " + str(clock.fps()) +'\t' +\
                str(1000/(pyb.millis()-start)))
        start = pyb.millis()
    if not tags_found:
        if tags[buff_idx].tag_sent:
                # only set tag_ready False if the previous tag has been sent
                #likely we'll want to set a timeout on this eventually to avoid stale tags
            tags[buff_idx].tag_ready = False
            LED(2).off()
        if tags[buff_idx].tag_ready and \
                not tags[buff_idx].tag_sent:
            tags[buff_idx].is_stale()
        return # No detections.
    else:
            #NOTE: return output_tag if you intend to have more than 1 tag in FOV at a time
            #output_tag = max(tags, key = lambda t: t.w() * t.h())
        if tags[buff_idx].mutex.test():
            tags[buff_idx].tag_ready = True
            tags[buff_idx].tag_sent = False
            tags[buff_idx].tag_time = pyb.millis()

            LED(2).on()
            tags[buff_idx].tag_dst = _pack_tag(tags_found[0])
            tags[buff_idx].mutex.release()
            if not VCP:
                print("Tag found:[cx=%d, cy=%d, id=%d, rot=%d]" \
                % struct.unpack("<HHHH",tags[buff_idx].tag_dst))
            ping = not ping
        else:
            if not VCP:
                print("Tag found but we can't get the mutex")
            else:
                pass


    #Saving takes too long
    #interface.schedule_callback(saveImage)

# When called returns the x/y centroid, id number, and rotation of the largest
# AprilTag within the OpenMV Cam's field-of-view.
# data is unused

def apriltag_detection(data):
    global tags
    global ping

    buff_idx=0
    if ping:
        buff_idx=1
    else: #pong
        buff_idx=0
    if tags[buff_idx].is_stale():
            return bytes()
    if tags[buff_idx].tag_ready:
        if not tags[buff_idx].tag_sent:
            with tags[buff_idx].mutex:
                tags[buff_idx].tag_sent = True
                tags[buff_idx].tag_ready = False
                if not VCP:
                    print("Tag Detected [cx=%d, cy=%d, id=%d, rot=%d]" %
                    struct.unpack("<HHHH",tags[buff_idx].tag_dst))
                return tags[buff_idx].tag_dst
    return bytes()

# When called returns a json list of json apriltag objects for all apriltags in view.
# data is unused
def all_apriltag_detection(data):
    tags = sensor.snapshot().find_apriltags()
    if not tags: return bytes() # No detections.
    draw_detections(sensor.get_fb(), tags)
    return str(tags).encode()

def blink(led,t=20):
    LED(led).on()
    time.sleep_ms(t)
    LED(led).off()
def blink1(data):
    blink(1,t=100)
    blink(2,t=100)
    blink(3,t=100)
    return str('blink1').encode()

count = 0
def test(data):
    global count
    count+=1
    return str(count).encode()

# When called returns a jpeg compressed image from the OpenMV
# Cam in one RPC call.
#
# data is unused
def jpeg_snapshot(data):
    #sensor.set_pixformat(sensor.RGB565)
    #sensor.set_framesize(sensor.QVGA)
    return sensor.snapshot().compress(quality=90).bytearray()

# Register call backs.
interface.register_callback(apriltag_detection)
interface.register_callback(jpeg_snapshot)
    #interface.register_callback(all_apriltag_detection)
    #interface.register_callback(blink1)
    #interface.register_callback(saveImage) #using this cb w/o an sd card will brick the openmv board
    #interface.register_callback(test)

# Setup ISR
def cb(data):
    micropython.schedule(ISRCallback,None)

tim4 = pyb.Timer(4, \
            freq=15, \
            callback=cb)

# Once all call backs have been registered we can start
# processing remote events. interface.loop() does not return.

while(True):
    #    time.sleep_ms(500)
    #    t = apriltag_detection(None)
    try: #wrapping to guard against throwing inside a CB
        interface.loop()
    except Exception:
        #with an unexpected failure reset_board
        if VCP:
            pyb.hard_reset()
        else: #leave failures while debugging
            print("EXCEPTION!!")
tim4.callback(None)