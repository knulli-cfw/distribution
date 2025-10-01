
import os
import termios
from time import sleep

SERIAL_PORT = '/dev/ttyS5'

BAUD_RATE = 115200

# Map baud rate to termios constant
BAUD_MAP = {
    9600: termios.B9600,
    115200: termios.B115200,
    # Add other common baud rates as needed
}

def calculate_checksum(data:list[int]) -> int:
    return sum(data) & 0xFF
    
class RGBDriver:

    header = [1, 255] # mode 1, which is the mode where you can do raw rendering and max brightness (we will do that manually one layer above...)

    def __init__(self, extra) -> None:

        with open('/sys/class/power_supply/axp2202-battery/mcu_pwr', 'w') as _temp:
            _temp.write('1\n')

        
        ## set up the serial port
        self.rgb_serial = os.open(SERIAL_PORT, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK) # type: ignore

        attrs = termios.tcgetattr(self.rgb_serial)

        # Set baud rate
        attrs[4] = BAUD_MAP.get(BAUD_RATE)
        attrs[5] = BAUD_MAP.get(BAUD_RATE)

        # Configure raw mode: this is the equivalent of the `pyserial` settings
        # c_iflag: input modes
        attrs[0] &= ~(termios.IGNBRK | termios.BRKINT | termios.PARMRK | termios.ISTRIP
                    | termios.INLCR | termios.IGNCR | termios.ICRNL | termios.IXON)
        # c_oflag: output modes
        attrs[1] &= ~termios.OPOST
        # c_cflag: control modes
        attrs[2] &= ~(termios.CSIZE | termios.PARENB)
        attrs[2] |= termios.CS8
        # c_lflag: local modes
        attrs[3] &= ~(termios.ECHO | termios.ECHONL | termios.ICANON | termios.ISIG | termios.IEXTEN)

        # Set new attributes immediately
        termios.tcsetattr(self.rgb_serial, termios.TCSANOW, attrs)

        os.write(self.rgb_serial,  b"\x01\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
        
        sleep(0.1)

    # expects a list of rgb values [255,0,0, ... ]
    def render(self, rgb_data:list[int]) -> bytes:
        all_data = self.header + rgb_data
        checksum = calculate_checksum(all_data)

        return bytes(all_data+[checksum])
    
    def write(self, bytes:bytes):
        os.write(self.rgb_serial, bytes)
        termios.tcdrain(self.rgb_serial) # pyright: ignore[reportAttributeAccessIssue]
    
    def close(self) -> None:        
        os.close(self.rgb_serial)

    

