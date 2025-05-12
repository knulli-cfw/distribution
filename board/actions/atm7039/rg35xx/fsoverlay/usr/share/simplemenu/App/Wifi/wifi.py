#!/usr/bin/env python

#	wificonfig.py
#
#	Requires: pygame
#
#	Copyright (c) 2013 Hans Kokx
#
#	Licensed under the GNU General Public License, Version 3.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	http://www.gnu.org/copyleft/gpl.html
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.


'''

TODO:
* Add option to cancel connecting to a network
* Clean up host ap info display. It's ugly.

'''


import subprocess as SU
import sys, time, os, shutil
import pygame
from pygame.locals import *
import pygame.gfxdraw
from os import listdir
from urllib.parse import quote_plus, unquote_plus

# What is our wireless interface?
wlan = "wlan0"

## That's it for options. Everything else below shouldn't be edited.
confdir = "/mnt/SDCARD/App/Wifi/"
netconfdir = confdir+"networks/"
sysconfdir = "/appconfigs/"
datadir = "/mnt/SDCARD/App/Wifi/data/"

surface = pygame.display.set_mode((320,240))
selected_key = ''
passphrase = ''
active_menu = ''
encryptiontypes = ("WEP-40","WEP-128","WPA", "WPA2")
encryptionLabels = ('None', 'WEP', 'WPA', 'WPA2')
colors = {
		"darkbg": (41, 41, 41),
		"lightbg": (84, 84, 84),
		"activeselbg": (160, 24, 24),
		"inactiveselbg": (84, 84, 84),
		"activetext": (255, 255, 255),
		"inactivetext": (128, 128, 128),
		"lightgrey": (200,200,200),
		'logogcw': (255, 255, 255),
		'logoconnect': (216, 32, 32),
		"color": (255,255,255),
		"yellow": (128, 128, 0),
		"blue": (0, 0, 128),
		"red": (128, 0, 0),
		"green": (0, 128, 0),
		"black": (0, 0, 0),
		"white": (255, 255, 255),
		}

mac_addresses = {}


## Initialize the display, for pygame
if not pygame.display.get_init():
	pygame.display.init()
if not pygame.font.get_init():
	pygame.font.init()

surface.fill(colors["darkbg"])
pygame.mouse.set_visible(False)
pygame.key.set_repeat(199,69) #(delay,interval)

## Fonts
font_path   = '/mnt/SDCARD/Koriki/fonts/DejaVuSans.ttf'
font_tiny   = pygame.font.Font(font_path, 8)
font_small  = pygame.font.Font(font_path, 10)
font_medium = pygame.font.Font(font_path, 12)
font_large  = pygame.font.Font(font_path, 16)
font_huge   = pygame.font.Font(font_path, 48)
gcw_font        = pygame.font.Font(os.path.join(datadir, 'gcwzero.ttf'), 23)
font_mono_small = pygame.font.Font(os.path.join(datadir, 'Inconsolata.otf'), 11)

## File management
def createpaths(): # Create paths, if necessary
	if not os.path.exists(confdir):
		os.makedirs(confdir)
	if not os.path.exists(netconfdir):
		os.makedirs(netconfdir)
	if not os.path.exists(sysconfdir):
		os.makedirs(sysconfdir)

## Interface management
def ifdown(iface):
	#SU.Popen(['ifdown', iface], close_fds=True).wait()
	SU.Popen(['/sbin/ifconfig', iface, 'down'], close_fds=True).wait()
	SU.Popen(['sleep', '2'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'wpa_supplicant'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'udhcpc'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'hostapd'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'dnsmasq'], close_fds=True).wait()
	#SU.Popen(['ap', '--stop'], close_fds=True).wait()
	#SU.Popen(['/config/wifi/ssw01bClose.sh'], close_fds=True).wait()
	SU.Popen(['/customer/app/axp_test', 'wifioff'], close_fds=True).wait()

def ifup(iface):
	return SU.Popen(['ifup', iface], close_fds=True).wait() == 0

# Returns False if the interface was previously enabled
def enableiface(iface):
	check = checkinterfacestatus(iface)
	if check:
		return False

	modal("Enabling WiFi...")
	drawinterfacestatus()
	pygame.display.update()

	SU.Popen(['/customer/app/axp_test', 'wifion'], close_fds=True).wait()
	SU.Popen(['sleep', '2'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'wpa_supplicant'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'udhcpc'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'hostapd'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'dnsmasq'], close_fds=True).wait()
	while True:
		if SU.Popen(['/sbin/ifconfig', iface, 'up'], close_fds=True).wait() == 0:
			break
		time.sleep(0.1);
	SU.Popen(['/mnt/SDCARD/Koriki/bin/wpa_supplicant', '-B', '-D', 'nl80211', '-i', iface, '-c', '/appconfigs/wpa_supplicant.conf'], close_fds=True).wait()
	mac_addresses[iface] = getmac(iface)
	return True

def disableiface(iface):
	SU.Popen(['pkill', '-9', 'wpa_supplicant'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'udhcpc'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'hostapd'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'dnsmasq'], close_fds=True).wait()
	SU.Popen(['/customer/app/axp_test', 'wifioff'], close_fds=True).wait()

def udhcpc(iface):
	return SU.Popen(['udhcpc', '-i', iface, '-s', '/etc/init.d/udhcpc.script'], close_fds=True).wait() == 0
	
def getip(iface):
	with open(os.devnull, "w") as fnull:
		output = SU.Popen(['/sbin/ifconfig', iface],
				stderr=fnull, stdout=SU.PIPE, close_fds=True).stdout.readlines()

	for line in output:
		if line.strip().startswith("inet addr"):
			return str.strip(
					line[line.find('inet addr')+len('inet addr"') :
					line.find('Bcast')+len('Bcast')].rstrip('Bcast'))

def getmac(iface):
	try:
		with open("/sys/class/net/" + iface + "/address", "rb") as mac_file:
			return mac_file.readline(17)
	except IOError:
		return None  # WiFi is disabled

def getcurrentssid(iface): # What network are we connected to?
	if not checkinterfacestatus(iface):
		return None

	with open(os.devnull, "w") as fnull:
		output = SU.Popen(['/mnt/SDCARD/Koriki/bin/iwconfig', iface],
				stdout=SU.PIPE, stderr=fnull, close_fds=True).stdout.readlines()
	for line in output:
		if line.strip().startswith(iface):
			ssid = str.strip(line[line.find('ESSID')+len('ESSID:"'):line.find('Nickname:')+len('Nickname:')].rstrip(' Nickname:').rstrip('"'))
	return ssid

def checkinterfacestatus(iface):
	return getip(iface) != None

def connect(iface): # Connect to a network
	saved_file = netconfdir + quote_plus(ssid) + ".conf"
	if os.path.exists(saved_file):
		shutil.copy2(saved_file, sysconfdir+"config-"+iface+".conf")
		
	saved_file2 = netconfdir + quote_plus(ssid) + "_wpa.conf"
	if os.path.exists(saved_file2):
		shutil.copy2(saved_file2, sysconfdir+"wpa_supplicant.conf")

	if checkinterfacestatus(iface):
		disconnect(iface)
	
	disconnect(iface)
	enableiface(iface)
	modal("Connecting...")
	
	if not udhcpc(wlan):
		modal('Connection failed!', wait=True)
		return False
	
	modal('Connected!', timeout=True)
	pygame.display.update()
	drawstatusbar()
	drawinterfacestatus()
	return True

def disconnect(iface):
	if checkinterfacestatus(iface):
		modal("Disconnecting...")
		ifdown(iface)

def getnetworks(iface): # Run iwlist to get a list of networks in range
	wasnotenabled = enableiface(iface)
	modal("Scanning...")

	with open(os.devnull, "w") as fnull:
		output = SU.Popen(['/mnt/SDCARD/Koriki/bin/iwlist', iface, 'scan'],
				stdout=SU.PIPE, stderr=fnull, close_fds=True).stdout.readlines()
	for item in output:
		if item.strip().startswith('Cell'):
			# network is the current list corresponding to a MAC address {MAC:[]}
			network = networks.setdefault(parsemac(item), dict())

		elif item.strip().startswith('ESSID:'):
			network["ESSID"] = (parseessid(item))

		elif item.strip().startswith('IE:') and not item.strip().startswith('IE: Unknown') or item.strip().startswith('Encryption key:'):
			network["Encryption"] = (parseencryption(item))

		elif item.strip().startswith('Quality='):
			network["Quality"] = (parsequality(item))
		# Now the loop is over, we will probably find a MAC address and a new "network" will be created.
	redraw()

	if wasnotenabled:
		disableiface(iface)
	return networks

def listuniqssids():
	menuposition = 0
	uniqssid = {}
	uniqssids = {}

	for network, detail in networks.iteritems():
		if detail['ESSID'] not in uniqssids and detail['ESSID']:
			uniqssid = uniqssids.setdefault(detail['ESSID'], detail)
			uniqssid["menu"] = menuposition
			uniqssid["Encryption"] = detail['Encryption']
			menuposition += 1
	return uniqssids

## Parsing iwlist output for various components
def parsemac(macin):
	mac = str.strip(macin[macin.find("Address:")+len("Address: "):macin.find("\n")+len("\n")])
	return mac

def parseessid(essid):
	essid = str.strip(essid[essid.find('ESSID:"')+len('ESSID:"'):essid.find('"\n')+len('"\n')].rstrip('"\n'))
	return essid

def parsequality(quality):
	quality = quality[quality.find("Quality=")+len("Quality="):quality.find(" S")+len(" S")].rstrip(" S")
	if len(quality) < 1:
		quality = '0/100'
	return quality

def parseencryption(encryption):
	encryption = str.strip(encryption)

	if encryption.startswith('Encryption key:off'):
	 	encryption = "none"
	elif encryption.startswith('Encryption key:on'):
		encryption = "WEP-40"
	elif encryption.startswith("IE: WPA"):
		encryption = "WPA"
	elif encryption.startswith("IE: IEEE 802.11i/WPA2"):
		encryption = "WPA2"
	else:
		encryption = "Encrypted (unknown)"
	return encryption

def aafilledcircle(surface, color, center, radius):
	'''Helper function to draw anti-aliased circles using an interface similar
	to pygame.draw.circle.
	'''
	x, y = center
	pygame.gfxdraw.aacircle(surface, x, y, radius, color)
	pygame.gfxdraw.filled_circle(surface, x, y, radius, color)
	return Rect(x - radius, y - radius, radius * 2 + 1, radius * 2 + 1)

## Draw interface elements
class hint:
	global colors
	def __init__(self, button, text, x, y, bg=colors["darkbg"]):
		self.button = button
		self.text = text
		self.x = x
		self.y = y
		self.bg = bg
		self.drawhint()

	def drawhint(self):
		if self.button == 'l' or self.button == 'r':
			if self.button == 'l':
				aafilledcircle(surface, colors["black"], (self.x, self.y+5), 5)
				pygame.draw.rect(surface, colors["black"], (self.x-5, self.y+6, 10, 5))


			if self.button == 'r':
				aafilledcircle(surface, colors["black"], (self.x+15, self.y+5), 5)
				pygame.draw.rect(surface, colors["black"], (self.x+11, self.y+6, 10, 5))

			button = pygame.draw.rect(surface, colors["black"], (self.x, self.y, 15, 11))
			text = font_tiny.render(self.button.upper(), True, colors["white"], colors["black"])
			buttontext = text.get_rect()
			buttontext.center = button.center
			surface.blit(text, buttontext)

		if self.button == "select" or self.button == "start":
			lbox = aafilledcircle(surface, colors["black"], (self.x+5, self.y+5), 6)
			rbox = aafilledcircle(surface, colors["black"], (self.x+29, self.y+5), 6)
			straightbox = lbox.union(rbox)
			buttoncenter = straightbox.center
			if self.button == 'select':
				straightbox.y = lbox.center[1]
			straightbox.height = (straightbox.height + 1) / 2
			pygame.draw.rect(surface, colors["black"], straightbox)

			roundedbox = Rect(lbox.midtop, (rbox.midtop[0] - lbox.midtop[0], lbox.height - straightbox.height))
			if self.button == 'start':
				roundedbox.bottomleft = lbox.midbottom
			pygame.draw.rect(surface, colors["black"], roundedbox)
			text = font_tiny.render(self.button.upper(), True, colors["white"], colors["black"])
			buttontext = text.get_rect()
			buttontext.center = buttoncenter
			buttontext.move_ip(0, 1)
			surface.blit(text, buttontext)

			labelblock = pygame.draw.rect(surface, self.bg, (self.x+40,self.y,25,14))
			labeltext = font_tiny.render(self.text, True, colors["white"], self.bg)
			surface.blit(labeltext, labelblock)

		elif self.button in ('a', 'b', 'y', 'x'):
			if self.button == "a":
				color = colors["red"]
			elif self.button == "b":
				color = colors["yellow"]
			elif self.button == "y":
				color = colors["green"]
			elif self.button == "x":
				color = colors["blue"]

			labelblock = pygame.draw.rect(surface, self.bg, (self.x+10,self.y,35,14))
			labeltext = font_tiny.render(self.text, True, colors["white"], self.bg)
			surface.blit(labeltext, labelblock)

			button = aafilledcircle(surface, color, (self.x,self.y+5), 6) # (x, y)
			text = font_tiny.render(self.button.upper(), True, colors["white"], color)
			buttontext = text.get_rect()
			buttontext.center = button.center
			surface.blit(text, buttontext)

		elif self.button in ('left', 'right', 'up', 'down'):

			# Vertical
			pygame.draw.rect(surface, colors["black"], (self.x+5, self.y-1, 4, 12))
			pygame.draw.rect(surface, colors["black"], (self.x+6, self.y-2, 2, 14))

			# Horizontal
			pygame.draw.rect(surface, colors["black"], (self.x+1, self.y+3, 12, 4))
			pygame.draw.rect(surface, colors["black"], (self.x, self.y+4, 14, 2))

			if self.button == "left":
				pygame.draw.rect(surface, colors["white"], (self.x+2, self.y+4, 3, 2))
			elif self.button == "right":
				pygame.draw.rect(surface, colors["white"], (self.x+9, self.y+4, 3, 2))
			elif self.button == "up":
				pygame.draw.rect(surface, colors["white"], (self.x+6, self.y+1, 2, 3))
			elif self.button == "down":
				pygame.draw.rect(surface, colors["white"], (self.x+6, self.y+7, 2, 3))

			labelblock = pygame.draw.rect(surface, self.bg, (self.x+20,self.y,35,14))
			labeltext = font_tiny.render(self.text, True, (255, 255, 255), self.bg)
			surface.blit(labeltext, labelblock)

class LogoBar(object):
	'''The logo area at the top of the screen.'''

	def __init__(self):
		self.text1 = gcw_font.render('KORIKI', True, colors['logogcw'], colors['lightbg'])
		self.text2 = gcw_font.render('CONNECT', True, colors['logoconnect'], colors['lightbg'])

	def draw(self):
		pygame.draw.rect(surface, colors['lightbg'], (0,0,320,34))
		pygame.draw.line(surface, colors['white'], (0, 34), (320, 34))

		rect1 = self.text1.get_rect()
		rect1.topleft = (8 + 5 + 1, 5)
		surface.blit(self.text1, rect1)

		rect2 = self.text2.get_rect()
		rect2.topleft = rect1.topright
		surface.blit(self.text2, rect2)

def drawstatusbar(): # Set up the status bar
	global colors
	pygame.draw.rect(surface, colors['lightbg'], (0,224,320,16))
	pygame.draw.line(surface, colors['white'], (0, 223), (320, 223))
	wlantext = font_mono_small.render("...", True, colors['white'], colors['lightbg'])
	wlan_text = wlantext.get_rect()
	wlan_text.topleft = (2, 225)
	surface.blit(wlantext, wlan_text)

def drawinterfacestatus(): # Interface status badge
	global colors
	wlanstatus = checkinterfacestatus(wlan)
	if not wlanstatus:
		wlanstatus = wlan+" is off."
	else:
		wlanstatus = getcurrentssid(wlan)

	wlantext = font_mono_small.render(wlanstatus, True, colors['white'], colors['lightbg'])
	wlan_text = wlantext.get_rect()
	wlan_text.topleft = (2, 225)
	surface.blit(wlantext, wlan_text)

	# Note that the leading space here is intentional, to more cleanly overdraw any overly-long
	# strings written to the screen beneath it (i.e. a very long ESSID)
	if checkinterfacestatus(wlan):
		text = font_mono_small.render(" "+getip(wlan), True, colors['white'], colors['lightbg'])
		interfacestatus_text = text.get_rect()
		interfacestatus_text.topright = (317, 225)
		surface.blit(text, interfacestatus_text)
	else:
		mac = mac_addresses.get(wlan)  # grabbed by enableiface()
		if mac is not None:
			text = font_mono_small.render(" "+mac, True, colors['white'], colors['lightbg'])
			interfacestatus_text = text.get_rect()
			interfacestatus_text.topright = (317, 225)
			surface.blit(text, interfacestatus_text)

def redraw():
	global colors
	surface.fill(colors['darkbg'])
	logoBar.draw()
	mainmenu()
	if wirelessmenu is not None:
		wirelessmenu.draw()
		pygame.draw.rect(surface, colors['darkbg'], (0, 208, 320, 16))
		hint("select", "Edit", 4, 210)
		hint("a", "Connect", 75, 210)
		hint("b", "/", 130, 210)
		hint("left", "Back", 145, 210)
	if active_menu == "main":
		pygame.draw.rect(surface, colors['darkbg'], (0, 208, 320, 16))
		hint("a", "Select", 8, 210)
	if active_menu == "saved":
		hint("y", "Forget", 195, 210)

	drawstatusbar()
	drawinterfacestatus()
	pygame.display.update()

def modal(text, wait=False, timeout=False, query=False):
	global colors
	dialog = pygame.draw.rect(surface, colors['lightbg'], (64,88,192,72))
	pygame.draw.rect(surface, colors['white'], (62,86,194,74), 2)

	text = font_medium.render(text, True, colors['white'], colors['lightbg'])
	modal_text = text.get_rect()
	modal_text.center = dialog.center

	surface.blit(text, modal_text)
	pygame.display.update()

	if wait:
		abutton = hint("a", "Continue", 205, 145, colors['lightbg'])
		pygame.display.update()
	elif timeout:
		time.sleep(2.5)
		redraw()
	elif query:
		abutton = hint("a", "Confirm", 150, 145, colors['lightbg'])
		bbutton = hint("b", "Cancel", 205, 145, colors['lightbg'])
		pygame.display.update()
		while True:
			for event in pygame.event.get():
				if event.type == KEYDOWN:
					if event.key == K_SPACE:
						return True
					elif event.key == K_LCTRL:
						return

	if not wait:
		return

	while True:
		for event in pygame.event.get():
			if event.type == KEYDOWN and event.key == K_SPACE:
				redraw()
				return

## Connect to a network
def writeconfig(): # Write wireless configuration to disk
	global passphrase
	global encryption
	try:
		encryption
	except NameError:
		encryption = uniq[ssid]['Encryption']

	if passphrase:
		if passphrase == "none":
			passphrase = ""

	conf = netconfdir + quote_plus(ssid) + ".conf"

	f = open(conf, "w")
	f.write('WLAN_ESSID="'+ssid+'"\n')

	if encryption == "WEP-128":
		encryption = "wep"
		f.write('WLAN_PASSPHRASE="s:'+passphrase+'"\n')
	else:
		f.write('WLAN_PASSPHRASE="'+passphrase+'"\n')
		if encryption == "WEP-40":
			encryption = "wep"
		elif encryption == "WPA":
			encryption = "wpa"
		elif encryption == "WPA2":
			encryption = "wpa2"


	f.write('WLAN_ENCRYPTION="'+encryption+'"\n')
	f.write('WLAN_DHCP_RETRIES=20\n')
	f.close()
	
	conf2 = netconfdir + quote_plus(ssid) + "_wpa.conf"
	
	f2 = open(conf2, "w")
	f2.write('ctrl_interface=/var/run/wpa_supplicant\n')
	f2.write('update_config=1\n')
	f2.write('\n')
	f2.write('network={\n')
	f2.write('scan_ssid=1\n')
	f2.write('ssid="'+ssid+'"\n')
	if encryption == "WEP-128":
		encryption = "wep"
		f2.write('psk="s:'+passphrase+'"\n')
	else:
		f2.write('psk="'+passphrase+'"\n')
	f2.write('}\n')
	f2.close()

## HostAP
def startap():
	global wlan
	if checkinterfacestatus(wlan):
		disconnect(wlan)

	modal("Creating AP...")
	SU.Popen(['pkill', '-9', 'wpa_supplicant'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'udhcpc'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'hostapd'], close_fds=True).wait()
	SU.Popen(['pkill', '-9', 'dnsmasq'], close_fds=True).wait()
	SU.Popen(['/customer/app/axp_test', 'wifion'], close_fds=True).wait()
	SU.Popen(['sleep', '2'], close_fds=True).wait()
	#SU.Popen(['/config/wifi/ssw01bInit.sh'], close_fds=True).wait()
	while True:
		if SU.Popen(['/sbin/ifconfig', 'wlan0'], close_fds=True).wait() == 0:
			break
			time.sleep(0.1)
		else:
			#SU.Popen(['/config/wifi/ssw01bClose.sh'], close_fds=True).wait()
			modal('Failed to create AP...', wait=True)
			redraw()
			return False
		
	SU.Popen(['/sbin/ifconfig', 'wlan0', 'up'], close_fds=True).wait()
	SU.Popen(['/mnt/SDCARD/Koriki/bin/iwconfig', 'wlan0', 'mode', 'master'], close_fds=True).wait()
	SU.Popen(['/mnt/SDCARD/Koriki/bin/iw', 'dev', 'wlan0', 'set', 'type', '__ap'], close_fds=True).wait()
	SU.Popen(['/mnt/SDCARD/Koriki/bin/hostapd', '-P' ,'/var/run/hostapd', '-B', '-i', 'wlan0', '/mnt/SDCARD/App/Wifi/hostapd.conf'], close_fds=True).wait()
	time.sleep(2.0)
	SU.Popen(['/sbin/ifconfig', 'wlan0', '192.168.4.100', 'netmask', '255.255.255.0', 'up'], close_fds=True).wait()
	SU.Popen(['/mnt/SDCARD/Koriki/bin/dnsmasq', '-i', 'wlan0', '-C', '/mnt/SDCARD/App/Wifi/dnsmasq.conf'], close_fds=True)
	time.sleep(0.5)
	#SU.Popen(['/mnt/SDCARD/Koriki/bin/dhcpcd', '-f', '/mnt/SDCARD/App/Wifi/udhcpd.conf'], close_fds=True)
	#SU.Popen(['sysctl', '-w', 'net.ipv4.ip_forward=1'], close_fds=True).wait()
	modal('AP created!', timeout=True)
	return True
## Input methods

keyLayouts = {
	'qwertyNormal': (
			('`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='),
			('q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'),
			('a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\''),
			('z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'),
			),
	'qwertyShift': (
			('~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+'),
			('Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '|'),
			('A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"'),
			('Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?'),
			),
	'wep': (
			('1', '2', '3', '4'),
			('5', '6', '7', '8'),
			('9', '0', 'A', 'B'),
			('C', 'D', 'E', 'F'),
			),
	}
keyboardCycleOrder = ('wep', 'qwertyNormal', 'qwertyShift')
def nextKeyboard(board):
	return keyboardCycleOrder[
			(keyboardCycleOrder.index(board) + 1) % len(keyboardCycleOrder)
			]

class key:
	global colors
	def __init__(self):
		self.key = []
		self.selection_color = colors['activeselbg']
		self.text_color = colors['activetext']
		self.selection_position = (0,0)
		self.selected_item = 0

	def init(self, key, row, column):
		self.key = key
		self.row = row
		self.column = column
		self.drawkey()

	def drawkey(self):
		key_width = 16
		key_height = 16

		top = 136 + self.row * 20
		left = 32 + self.column * 20

		if len(self.key) > 1:
			key_width = 36
		keybox = pygame.draw.rect(surface, colors['lightbg'], (left,top,key_width,key_height))
		text = font_medium.render(self.key, True, colors['white'], colors['lightbg'])
		label = text.get_rect()
		label.center = keybox.center
		label.y -= 1
		surface.blit(text, label)

class radio:
	global colors
	def __init__(self):
		self.key = []
		self.selection_color = colors['activeselbg']
		self.text_color = colors['activetext']
		self.selection_position = (0,0)
		self.selected_item = 0

	def init(self, key, row, column):
		self.key = key
		self.row = row
		self.column = column
		self.drawkey()

	def drawkey(self):
		key_width = 64
		key_height = 16

		top = 136 + self.row * 20
		left = 32 + self.column * 64

		if len(self.key) > 1:
			key_width = 64
		radiobutton = aafilledcircle(surface, colors['white'], (left, top), 8)
		aafilledcircle(surface, colors['darkbg'], (left, top), 6)
		text = font_medium.render(self.key, True, (255, 255, 255), colors['darkbg'])
		label = text.get_rect()
		label.left = radiobutton.right + 8
		label.top = radiobutton.top + 4
		surface.blit(text, label)

def getSSID():
	global passphrase
	displayinputlabel("ssid")
	drawkeyboard("qwertyNormal")
	getinput("qwertyNormal", "ssid")
	ssid = passphrase
	passphrase = ''
	return ssid

def drawEncryptionType():
	global colors
	# Draw top background
	pygame.draw.rect(surface, colors['darkbg'], (0,40,320,200))

	# Draw footer
	pygame.draw.rect(surface, colors['lightbg'], (0,224,320,16))
	pygame.draw.line(surface, colors['white'], (0, 223), (320, 223))
	hint("select", "Cancel", 4, 227, colors['lightbg'])
	hint("a", "Enter", 285, 227, colors['lightbg'])

	# Draw the keys
	z = radio()
	for i, label in enumerate(encryptionLabels):
		z.init(label, 0, i)

	pygame.display.update()

def displayencryptionhint():
	global colors
	global encryption

	try:
		if encryption:
			if encryption == "wep":
				encryption = "WEP-40"
	except:
		pass

	try:
		if encryption:
			pygame.draw.rect(surface, colors['darkbg'], (0,100,320,34))
			hint("l", "L", 16, 113)
			hint("r", "R", 289, 113)

			pos = 1
			for enc in encryptiontypes:
				x = (pos * 60) - 20
				labelblock = pygame.Rect(x,111,55,14)
				if enc == encryption:
					# Draw a selection rectangle for the active encryption method
					pygame.draw.rect(surface, colors['activeselbg'], labelblock)
				labeltext = font_small.render(enc.center(10, ' '), True, colors["white"])
				surface.blit(labeltext, labelblock)
				pos += 1
			pygame.display.update()
	except NameError:
		pass

def chooseencryption(direction):
	global selected_key

	encryption = ''

	if direction == "left":
		selected_key[0] = (selected_key[0] - 1) % len(encryptionLabels)

	elif direction == "right":
		selected_key[0] = (selected_key[0] + 1) % len(encryptionLabels)

	elif direction == "select":
		encryption = encryptionLabels[selected_key[0]]
		if encryption == "WEP":
			encryption = "WEP-40"

	elif direction == "init":
		selected_key = [0,0]

	drawEncryptionType()
	pos = (32 + selected_key[0] * 64, 136)
	aafilledcircle(surface, colors['activeselbg'], pos, 6)
	pygame.display.update()

	return encryption

def prevEncryption():
	global encryption

	for i, s in enumerate(encryptiontypes):
		if encryption in s:
			x = encryptiontypes.index(s)-1
			try:
				encryption = encryptiontypes[x]
				return
			except IndexError:
				encryption = encryptiontypes[:-1]
				return

def nextEncryption():
	global encryption

	for i, s in enumerate(encryptiontypes):
		if encryption in s:
			x = encryptiontypes.index(s)+1
			try:
				encryption = encryptiontypes[x]
				return
			except IndexError:
				encryption = encryptiontypes[0]
				return

def getEncryptionType():
	chooseencryption("init")
	while True:
		for event in pygame.event.get():
			if event.type == KEYDOWN:
				if event.key == K_LEFT:		# Move cursor left
					chooseencryption("left")
				if event.key == K_RIGHT:	# Move cursor right
					chooseencryption("right")
				if event.key == K_SPACE:	# A button
					return chooseencryption("select")
				if event.key == K_RCTRL:	# Select key
					return 'cancel'

def drawkeyboard(board):
	global colors

	# Draw keyboard background
	pygame.draw.rect(surface, colors['darkbg'], (0,134,320,106))

	# Draw bottom background
	pygame.draw.rect(surface, colors['lightbg'], (0,224,320,16))
	pygame.draw.line(surface, colors['white'], (0, 223), (320, 223))

	hint("select", "Cancel", 4, 227, colors['lightbg'])
	hint("start", "Finish", 75, 227, colors['lightbg'])
	hint("y", "Delete", 155, 227, colors['lightbg'])
	if not board == "wep":
		hint("x", "Shift", 200, 227, colors['lightbg'])
		hint("b", "Space", 240, 227, colors['lightbg'])

	else:
		hint("x", "Full KB", 200, 227, colors['lightbg'])

	hint("a", "Enter", 285, 227, colors['lightbg'])

	# Draw the keys
	z = key()
	for row, rowData in enumerate(keyLayouts[board]):
		for column, label in enumerate(rowData):
			z.init(label, row, column)

	pygame.display.update()

def getinput(board, kind, ssid=""):
	selectkey(board, kind)
	return softkeyinput(board, kind, ssid)

def softkeyinput(keyboard, kind, ssid):
	global passphrase
	global encryption
	global securitykey
	def update():
		displayinputlabel("key")
		displayencryptionhint()

	while True:
		event = pygame.event.wait()

		if event.type == KEYDOWN:
			if event.key == K_RETURN:		# finish input
				selectkey(keyboard, kind, "enter")
				redraw()
				if ssid == '':
					return False
				writeconfig()
				connect(wlan)
				return True

			if event.key == K_UP:		# Move cursor up
				selectkey(keyboard, kind, "up")
			if event.key == K_DOWN:		# Move cursor down
				selectkey(keyboard, kind, "down")
			if event.key == K_LEFT:		# Move cursor left
				selectkey(keyboard, kind, "left")
			if event.key == K_RIGHT:	# Move cursor right
				selectkey(keyboard, kind, "right")
			if event.key == K_SPACE:	# A button
				selectkey(keyboard, kind, "select")
			if event.key == K_LCTRL:		# B button
				if encryption != "WEP-40":
					selectkey(keyboard, kind, "space")
			if event.key == K_LSHIFT:	# X button (swap keyboards)
				keyboard = nextKeyboard(keyboard)
				drawkeyboard(keyboard)
				selectkey(keyboard, kind, "swap")
			if event.key == K_LALT:	# Y button
				selectkey(keyboard, kind, "delete")
			if event.key == K_RCTRL:	# Select key
				passphrase = ''
				try:
					encryption
				except NameError:
					pass
				else:
					del encryption

				try:
					securitykey
				except NameError:
					pass
				else:
					del securitykey
				redraw()
				return False
			if kind == "key":
				if event.key == K_e:			# L shoulder button
					prevEncryption()
					update()
				if event.key == K_t:	# R shoulder button
					nextEncryption()
					update()

def displayinputlabel(kind, size=24): # Display passphrase on screen
	global colors
	global encryption

	def update():
		displayencryptionhint()

	if kind == "ssid":
		# Draw SSID and encryption type labels
		pygame.draw.rect(surface, colors['darkbg'], (0,100,320,34))
		labelblock = pygame.draw.rect(surface, colors['white'], (0,35,320,20))
		labeltext = font_large.render("Enter new SSID", True, colors['lightbg'], colors['white'])
		label = labeltext.get_rect()
		label.center = labelblock.center
		surface.blit(labeltext, label)

	elif kind == "key":
		displayencryptionhint()
		# Draw SSID and encryption type labels
		labelblock = pygame.draw.rect(surface, colors['white'], (0,35,320,20))
		labeltext = font_large.render("Enter "+encryption+" key", True, colors['lightbg'], colors['white'])
		label = labeltext.get_rect()
		label.center = labelblock.center
		surface.blit(labeltext, label)
		update()

	# Input area
	bg = pygame.draw.rect(surface, colors['white'], (0, 55, 320, 45))
	text = "[ "
	text += passphrase
	text += " ]"
	pw = font_mono_small.render(text, True, (0, 0, 0), colors['white'])
	pwtext = pw.get_rect()
	pwtext.center = bg.center
	surface.blit(pw, pwtext)
	pygame.display.update()

def selectkey(keyboard, kind, direction=""):
	def highlightkey(keyboard, pos='[0,0]'):
		drawkeyboard(keyboard)
		pygame.display.update()

		left_margin = 32
		top_margin = 136

		if pos[0] > left_margin:
			x = left_margin + (16 * (pos[0]))
		else:
			x = left_margin + (16 * pos[0]) + (pos[0] * 4)


		if pos[1] > top_margin:
			y = top_margin + (16 * (pos[1]))
		else:
			y = top_margin + (16 * pos[1]) + (pos[1] * 4)

		pointlist = [
				(x, y),
				(x + 16, y),
				(x + 16, y + 16),
				(x, y + 16),
				(x, y)
				]
		lines = pygame.draw.lines(surface, (255,255,255), True, pointlist, 1)
		pygame.display.update()

	global selected_key
	global passphrase

	if not selected_key:
		selected_key = [0,0]

	def clampRow():
		selected_key[1] = min(selected_key[1], len(layout) - 1)
	def clampColumn():
		selected_key[0] = min(selected_key[0], len(layout[selected_key[1]]) - 1)

	layout = keyLayouts[keyboard]
	if direction == "swap":
		# Clamp row first since each row can have a different number of columns.
		clampRow()
		clampColumn()
	elif direction == "up":
		selected_key[1] = (selected_key[1] - 1) % len(layout)
		clampColumn()
	elif direction == "down":
		selected_key[1] = (selected_key[1] + 1) % len(layout)
		clampColumn()
	elif direction == "left":
		selected_key[0] = (selected_key[0] - 1) % len(layout[selected_key[1]])
	elif direction == "right":
		selected_key[0] = (selected_key[0] + 1) % len(layout[selected_key[1]])
	elif direction == "select":
		passphrase += layout[selected_key[1]][selected_key[0]]
		if len(passphrase) > 20:
			logoBar.draw()
			displayinputlabel(kind, 12)
		else:
			displayinputlabel(kind)
	elif direction == "space":
		passphrase += ' '
		if len(passphrase) > 20:
			logoBar.draw()
			displayinputlabel(kind, 12)
		else:
			displayinputlabel(kind)
	elif direction == "delete":
		if len(passphrase) > 0:
			passphrase = passphrase[:-1]
			logoBar.draw()
			if len(passphrase) > 20:
				displayinputlabel(kind, 12)
			else:
				displayinputlabel(kind)

	highlightkey(keyboard, selected_key)

class Menu:
	font = font_medium
	dest_surface = surface
	canvas_color = colors["darkbg"]

	elements = []

	def __init__(self):
		self.set_elements([])
		self.selected_item = 0
		self.origin = (0,0)
		self.menu_width = 0
		self.menu_height = 0
		self.selection_color = colors["activeselbg"]
		self.text_color = colors["activetext"]
		self.font = font_medium

	def move_menu(self, top, left):
		self.origin = (top, left)

	def set_colors(self, text, selection, background):
		self.text_color = text
		self.selection_color = selection

	def set_elements(self, elements):
		self.elements = elements

	def get_position(self):
		return self.selected_item

	def get_selected(self):
		return self.elements[self.selected_item]

	def init(self, elements, dest_surface):
		self.set_elements(elements)
		self.dest_surface = dest_surface

	def draw(self,move=0):
		# Clear any old text (like from apinfo()), but don't overwrite button hint area above statusbar
		pygame.draw.rect(surface, colors['darkbg'], (0,35,320,173))

		if len(self.elements) == 0:
			return

		self.selected_item = (self.selected_item  + move) % len(self.elements)

		# Which items are to be shown?
		if self.selected_item <= 2: # We're at the top
			visible_elements = self.elements[0:6]
			selected_within_visible = self.selected_item
		elif self.selected_item >= len(self.elements) - 3: # We're at the bottom
			visible_elements = self.elements[-6:]
			selected_within_visible = self.selected_item - (len(self.elements) - len(visible_elements))
		else: # The list is larger than 5 elements, and we're in the middle
			visible_elements = self.elements[self.selected_item - 2:self.selected_item + 3]
			selected_within_visible = 2

		# What width does everything have?
		max_width = max([self.get_item_width(visible_element) for visible_element in visible_elements])
		# And now the height
		heights = [self.get_item_height(visible_element) for visible_element in visible_elements]
		total_height = sum(heights)

		# Background
		menu_surface = pygame.Surface((max_width, total_height))
		menu_surface.fill(self.canvas_color)

		# Selection
		left = 0
		top = sum(heights[0:selected_within_visible])
		width = max_width
		height = heights[selected_within_visible]
		selection_rect = (left, top, width, height)
		pygame.draw.rect(menu_surface,self.selection_color,selection_rect)

		# Clear any error elements
		error_rect = (left+width+8, 35, 192, 172)
		pygame.draw.rect(surface,colors['darkbg'],error_rect)

		# Elements
		top = 0
		for i in range(len(visible_elements)):
			self.render_element(menu_surface, visible_elements[i], 0, top)
			top += heights[i]
		self.dest_surface.blit(menu_surface,self.origin)
		return self.selected_item

	def get_item_height(self, element):
		render = self.font.render(element, 1, self.text_color)
		spacing = 5
		return render.get_rect().height + spacing * 2

	def get_item_width(self, element):
		render = self.font.render(element, 1, self.text_color)
		spacing = 5
		return render.get_rect().width + spacing * 2

	def render_element(self, menu_surface, element, left, top):
		render = self.font.render(element, 1, self.text_color)
		spacing = 5
		menu_surface.blit(render, (left + spacing, top + spacing, render.get_rect().width, render.get_rect().height))

class NetworksMenu(Menu):
	def set_elements(self, elements):
		self.elements = elements

	def get_item_width(self, element):
		the_ssid = element[0]
		render = self.font.render(the_ssid, 1, self.text_color)
		spacing = 15
		return render.get_rect().width + spacing * 2

	def get_item_height(self, element):
		render = self.font.render(element[0], 1, self.text_color)
		spacing = 6
		return (render.get_rect().height + spacing * 2) + 5

	def render_element(self, menu_surface, element, left, top):
		the_ssid = element[0]

		def qualityPercent(x):
			percent = (float(x.split("/")[0]) / float(x.split("/")[1])) * 100
			if percent > 100:
				percent = 100
			return int(percent)
		## Wifi signal icons
		percent = qualityPercent(element[1])

		if percent >= 6 and percent <= 24:
			signal_icon = 'wifi-0.png'
		elif percent >= 25 and percent <= 49:
			signal_icon = 'wifi-1.png'
		elif percent >= 50 and percent <= 74:
			signal_icon = 'wifi-2.png'
		elif percent >= 75:
			signal_icon = 'wifi-3.png'
		else:
			signal_icon = 'transparent.png'

		## Encryption information
		enc_type = element[2]
		if enc_type == "NONE" or enc_type == '':
			enc_icon = "open.png"
			enc_type = "Open"
		elif enc_type == "WPA" or enc_type == "wpa":
			enc_icon = "closed.png"
		elif enc_type == "WPA2" or enc_type == "wpa2":
			enc_icon = "closed.png"
		elif enc_type == "WEP-40" or enc_type == "WEP-128" or enc_type == "wep" or enc_type == "WEP":
			enc_icon = "closed.png"
			enc_type = "WEP"
		else:
			enc_icon = "unknown.png"
			enc_type = "(Unknown)"


		qual_img = pygame.image.load((os.path.join(datadir, signal_icon))).convert_alpha()
		enc_img = pygame.image.load((os.path.join(datadir, enc_icon))).convert_alpha()
		transparent_qual = qual_img.copy()
		transparent_qual.fill((255, 255, 255, 100), special_flags=pygame.BLEND_RGBA_MULT)
		transparent_enc = enc_img.copy()
		transparent_enc.fill((255, 255, 255, 100), special_flags=pygame.BLEND_RGBA_MULT)

		ssid = font_mono_small.render(the_ssid, 1, self.text_color)
		enc = font_small.render(enc_type, 1, colors["lightgrey"])
		#strength = font_small.render(str(str(percent) + "%").rjust(4), 1, colors["lightgrey"])
		#qual = font_small.render(element[1], 1, colors["lightgrey"])
		spacing = 2

		menu_surface.blit(ssid, (left + spacing, top))
		menu_surface.blit(enc, (left + enc_img.get_rect().width + 12, top + 18))
		menu_surface.blit(enc_img, (left + 8, (top + 24) - (enc_img.get_rect().height / 2)))
		# menu_surface.blit(strength, (left + 137, top + 18, strength.get_rect().width, strength.get_rect().height))
		qual_x = left + 200 - qual_img.get_rect().width - 3
		qual_y = top + 7 + 6 
		menu_surface.blit(qual_img, (qual_x, qual_y))
		pygame.display.update()

	def draw(self,move=0):
		if len(self.elements) == 0:
			return

		if move != 0:
			self.selected_item += move
			if self.selected_item < 0:
				self.selected_item = 0
			elif self.selected_item >= len(self.elements):
				self.selected_item = len(self.elements) - 1

		# Which items are to be shown?
		if self.selected_item <= 2: # We're at the top
			visible_elements = self.elements[0:5]
			selected_within_visible = self.selected_item
		elif self.selected_item >= len(self.elements) - 3: # We're at the bottom
			visible_elements = self.elements[-5:]
			selected_within_visible = self.selected_item - (len(self.elements) - len(visible_elements))
		else: # The list is larger than 5 elements, and we're in the middle
			visible_elements = self.elements[self.selected_item - 2:self.selected_item + 3]
			selected_within_visible = 2

		max_width = 320 - self.origin[0] - 3

		# And now the height
		heights = [self.get_item_height(visible_element) for visible_element in visible_elements]
		total_height = sum(heights)

		# Background
		menu_surface = pygame.Surface((max_width, total_height))
		menu_surface.fill(self.canvas_color)

		# Selection
		left = 0
		top = sum(heights[0:selected_within_visible])
		width = max_width
		height = heights[selected_within_visible]
		selection_rect = (left, top, width, height)
		pygame.draw.rect(menu_surface,self.selection_color,selection_rect)

		# Elements
		top = 0
		for i in range(len(visible_elements)):
			self.render_element(menu_surface, visible_elements[i], 0, top)
			top += heights[i]
		self.dest_surface.blit(menu_surface,self.origin)
		return self.selected_item

def to_menu(new_menu):
	global colors
	if new_menu == "main":
		menu.set_colors(colors['activetext'], colors['activeselbg'], colors['darkbg'])
		if wirelessmenu is not None:
			wirelessmenu.set_colors(colors['inactivetext'], colors['inactiveselbg'], colors['darkbg'])
	elif new_menu == "ssid" or new_menu == "saved":
		menu.set_colors(colors['inactivetext'], colors['inactiveselbg'], colors['darkbg'])
		wirelessmenu.set_colors(colors['activetext'], colors['activeselbg'], colors['darkbg'])
	return new_menu

wirelessmenu = None
menu = Menu()
menu.move_menu(3, 41)

def mainmenu():
	global wlan
	elems = ['Quit']

	try:
		ap = getcurrentssid(wlan).split("-")[1]
		file = open('/sys/class/net/wlan0/address', 'r')
		mac = file.read().strip('\n').replace(":", "")
		file.close()
		if mac == ap:
			elems = ['AP info'] + elems
	except:
		elems = ['Create AP'] + elems

	elems = ["Saved Networks", 'Scan for APs', "Manual Setup"] + elems

	if checkinterfacestatus(wlan):
		elems = ['Disconnect'] + elems

	menu.init(elems, surface)
	menu.draw()

def apinfo():
	global wlan

	try:
		ap = getcurrentssid(wlan).split("-")[1]
		file = open('/sys/class/net/wlan0/address', 'r')
		mac = file.read().strip('\n').replace(":", "")
		file.close()
		if mac == ap:
			ssidlabel = "SSID"
			renderedssidlabel = font_huge.render(ssidlabel, True, colors["lightbg"], colors["darkbg"])
			ssidlabelelement = renderedssidlabel.get_rect()
			ssidlabelelement.right = 318
			ssidlabelelement.top = 34
			surface.blit(renderedssidlabel, ssidlabelelement)

			ssid = getcurrentssid(wlan)
			renderedssid = font_mono_small.render(ssid, True, colors["white"], colors["darkbg"])
			ssidelement = renderedssid.get_rect()
			ssidelement.right = 315
			ssidelement.top = 96
			surface.blit(renderedssid, ssidelement)

			enclabel = "Key"
			renderedenclabel = font_huge.render(enclabel, True, colors["lightbg"], colors["darkbg"])
			enclabelelement = renderedenclabel.get_rect()
			enclabelelement.right = 314 # Drawn a bit leftwards versus "SSID" text, so both right-align pixel-perfectly
			enclabelelement.top = 114
			surface.blit(renderedenclabel, enclabelelement)

			renderedencp = font_mono_small.render(mac, True, colors["white"], colors["darkbg"])
			encpelement = renderedencp.get_rect()
			encpelement.right = 315
			encpelement.top = 180
			surface.blit(renderedencp, encpelement)

			pygame.display.update()
	except:
		text = ":("
		renderedtext = font_huge.render(text, True, colors["lightbg"], colors["darkbg"])
		textelement = renderedtext.get_rect()
		textelement.left = 192
		textelement.top = 96
		surface.blit(renderedtext, textelement)
		pygame.display.update()

def create_wireless_menu():
	global wirelessmenu
	wirelessmenu = NetworksMenu()
	wirelessmenu.move_menu(116,40)

def destroy_wireless_menu():
	global wirelessmenu
	wirelessmenu = None

def create_saved_networks_menu():
	global uniq

	uniqssids = {}
	menu = 1
	for confName in sorted(listdir(netconfdir)):
		if not confName.endswith('.conf'):
			continue
		ssid = unquote_plus(confName[:-5])

		detail = {
			'ESSID': ssid,
			'Encryption': '',
			'Key': '',
			'Quality': '0/1',
			'menu': menu,
			}
		try:
			with open(netconfdir + confName) as f:
				for line in f:
					key, value = line.split('=', 1)
					key = key.strip()
					value = value.strip()
					if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
						value = value[1:-1]

					if key == 'WLAN_ESSID':
						detail['ESSID'] = value
					elif key == 'WLAN_ENCRYPTION':
						detail['Encryption'] = value
					elif key == 'WLAN_PASSPHRASE':
						# TODO: fix for 128-bit wep
						detail['Key'] = value
		except IOError as ex:
			print('Error reading conf:', ex)
		except ValueError as ex:
			print('Error parsing conf line:', line.strip())
		else:
			uniqssids[ssid] = detail
			menu += 1
	uniq = uniqssids

	if uniq:
		l = []
		for item in sorted(uniq.iterkeys(), key=lambda x: uniq[x]['menu']):
			detail = uniq[item]
			l.append([ detail['ESSID'], detail['Quality'], detail['Encryption'].upper()])
		create_wireless_menu()
		wirelessmenu.init(l, surface)
		wirelessmenu.draw()
	else:
		text = 'empty'
		renderedtext = font_huge.render(text, True, colors["lightbg"], colors["darkbg"])
		textelement = renderedtext.get_rect()
		textelement.left = 152
		textelement.top = 96
		surface.blit(renderedtext, textelement)
		pygame.display.update()

def convert_file_names():
	"""In the directory containing WiFi network configuration files, removes
	backslashes from file names created by older versions of GCW Connect."""
	try:
		confNames = listdir(netconfdir)
	except IOError as ex:
		print("Failed to list files in...")# '%s': %s" (netconfdir, ex))
	else:
		for confName in confNames:
			if not confName.endswith('.conf'):
				continue
			if '\\' in confName:
				old, new = confName, quote_plus(confName.replace('\\', ''))
				try:
					os.rename(os.path.join(netconfdir, old), os.path.join(netconfdir, new))
				except IOError as ex:
					print("Failed to rename old-style network configuration file '%s' to '%s': %s" % (os.path.join(netconfdir, old), new, ex))

if __name__ == "__main__":
	# Persistent variables
	networks = {}
	uniqssids = {}
	active_menu = "main"

	try:
		createpaths()
	except:
		pass ## Can't create directories. Great for debugging on a pc.
	else:
		convert_file_names()

	logoBar = LogoBar()

	redraw()
	while True:
		time.sleep(0.01)
		for event in pygame.event.get():
			## Miyoo mini keycodes:
			# A = K_SPACE
			# B = K_LCTRL
			# Y = K_LALT
			# X = K_LSHIFT
			# L = K_e
			# R = K_t
			# L2 = K_TAB
			# R2 = K_BACKSPACE
			# start = K_RETURN
			# select = K_RCTRL
			# menu = K_ESCAPE
			# power down = K_POWER
			
			if event.type == QUIT:
				pygame.display.quit()
				sys.exit()

			elif event.type == KEYDOWN:
				if event.key == K_POWER: # Power down
					pass
				elif event.key == K_e: # Left shoulder button
					pass
				elif event.key == K_t: # Right shoulder button
					pass
				elif event.key == K_ESCAPE:	# menu
					pygame.display.quit()
					sys.exit()
					pass
				elif event.key == K_UP: # Arrow up the menu
					if active_menu == "main":
						menu.draw(-1)
					elif active_menu == "ssid" or active_menu == "saved":
						wirelessmenu.draw(-1)
				elif event.key == K_DOWN: # Arrow down the menu
					if active_menu == "main":
						menu.draw(1)
					elif active_menu == "ssid" or active_menu == "saved":
						wirelessmenu.draw(1)
				elif event.key == K_RIGHT:
					if wirelessmenu is not None and active_menu == "main":
						active_menu = to_menu("ssid")
						redraw()
				elif event.key == K_LCTRL or event.key == K_LEFT:
					if active_menu == "ssid" or active_menu == "saved":
						destroy_wireless_menu()
						active_menu = to_menu("main")
						del uniq
						redraw()
					elif event.key == K_LCTRL:
						pygame.display.quit()
						sys.exit()
				elif event.key == K_LALT:
					if active_menu == "saved":
						confirm = modal("Forget AP configuration?", query=True)
						if confirm:
							os.remove(netconfdir+quote_plus(str(wirelessmenu.get_selected()[0]))+".conf")
							os.remove(netconfdir+quote_plus(str(wirelessmenu.get_selected()[0]))+"_wpa.conf")
						create_saved_networks_menu()
						redraw()
						if len(uniq) < 1:
							destroy_wireless_menu()
							active_menu = to_menu("main")
							redraw()
				elif event.key == K_SPACE or event.key == K_RETURN:
					# Main menu
					if active_menu == "main":
						if menu.get_selected() == 'Disconnect':
							disconnect(wlan)
							redraw()
							pygame.display.update()
						elif menu.get_selected() == 'Scan for APs':
							try:
								getnetworks(wlan)
								uniq = listuniqssids()
							except:
								uniq = {}
								text = ":("
								renderedtext = font_huge.render(text, True, colors["lightbg"], colors["darkbg"])
								textelement = renderedtext.get_rect()
								textelement.left = 192
								textelement.top = 96
								surface.blit(renderedtext, textelement)
								pygame.display.update()

							l = []
							if len(uniq) < 1:
								text = ":("
								renderedtext = font_huge.render(text, True, colors["lightbg"], colors["darkbg"])
								textelement = renderedtext.get_rect()
								textelement.left = 192
								textelement.top = 96
								surface.blit(renderedtext, textelement)
								pygame.display.update()
							else:
								for item in sorted(uniq.iterkeys(), key=lambda x: uniq[x]['menu']):
									for network, detail in uniq.iteritems():
										if network == item:
											try:
												detail['Quality']
											except KeyError:
												detail['Quality'] = "0/1"
											try:
												detail['Encryption']
											except KeyError:
												detail['Encryption'] = ""

											menuitem = [ detail['ESSID'], detail['Quality'], detail['Encryption']]
											l.append(menuitem)

								create_wireless_menu()
								wirelessmenu.init(l, surface)
								wirelessmenu.draw()

								active_menu = to_menu("ssid")
								redraw()
						elif menu.get_selected() == 'Manual Setup':
							ssid = ''
							encryption = ''
							passphrase = ''
							selected_key = ''
							securitykey = ''

							# Get SSID from the user
							ssid = getSSID()
							if ssid == '':
								pass
							else:
								drawEncryptionType()
								encryption = getEncryptionType()
								displayinputlabel("key")
								displayencryptionhint()

								# Get key from the user
								if not encryption == 'None':
									if encryption == "WPA":
										drawkeyboard("qwertyNormal")
										securitykey = getinput("qwertyNormal", "key", ssid)
									elif encryption == "WPA2":
										drawkeyboard("qwertyNormal")
										securitykey = getinput("qwertyNormal", "key", ssid)
									elif encryption == "WEP-40":
										drawkeyboard("wep")
										securitykey = getinput("wep", "key", ssid)
									elif encryption == 'cancel':
										del encryption, ssid, securitykey
										redraw()
								else:
									encryption = "none"
									redraw()
									writeconfig()
									connect(wlan)
								try:
									encryption
								except NameError:
									pass

						elif menu.get_selected() == 'Saved Networks':
							create_saved_networks_menu()
							try:
								active_menu = to_menu("saved")
								redraw()
							except:
								active_menu = to_menu("main")

						elif menu.get_selected() == 'Create AP':
							startap()

						elif menu.get_selected() == 'AP info':
							apinfo()

						elif menu.get_selected() == 'Quit':
							pygame.display.quit()
							sys.exit()

					# SSID menu
					elif active_menu == "ssid":
						ssid = ""
						for network, detail in uniq.iteritems():
							position = str(wirelessmenu.get_position())
							if str(detail['menu']) == position:
								if detail['ESSID'].split("-")[0] == "gcwzero":
									ssid = detail['ESSID']
									conf = netconfdir + quote_plus(ssid) + ".conf"
									encryption = "WPA2"
									passphrase = ssid.split("-")[1]
									connect(wlan)
								else:
									ssid = detail['ESSID']
									conf = netconfdir + quote_plus(ssid) + ".conf"
									encryption = detail['Encryption']
									if not os.path.exists(conf):
										if encryption == "none":
											passphrase = "none"
											encryption = "none"
											writeconfig()
											connect(wlan)
										elif encryption == "WEP-40" or encryption == "WEP-128":
											passphrase = ''
											selected_key = ''
											securitykey = ''
											displayinputlabel("key")
											drawkeyboard("wep")
											encryption = "wep"
											passphrase = getinput("wep", "key", ssid)
										else:
											passphrase = ''
											selected_key = ''
											securitykey = ''
											displayinputlabel("key")
											drawkeyboard("qwertyNormal")
											passphrase = getinput("qwertyNormal", "key", ssid)
									else:
										connect(wlan)
								break

					# Saved Networks menu
					elif active_menu == "saved":
						ssid = ''
						for network, detail in uniq.iteritems():
							position = str(wirelessmenu.get_position()+1)
							if str(detail['menu']) == position:
								encryption = detail['Encryption']
								ssid = str(detail['ESSID'])
								shutil.copy2(netconfdir + quote_plus(ssid) + ".conf", sysconfdir+"config-"+wlan+".conf")
								shutil.copy2(netconfdir + quote_plus(ssid) + "_wpa.conf", sysconfdir+"wpa_supplicant.conf")
								passphrase = detail['Key']
								enableiface(wlan)
								connect(wlan)
								break

				elif event.key == K_RCTRL:
					if active_menu == "ssid": # Allow us to edit the existing key
						ssid = ""
						for network, detail in uniq.iteritems():
							position = str(wirelessmenu.get_position())
							if str(detail['menu']) == position:
								ssid = network
								encryption = detail['Encryption']
								if detail['Encryption'] == "none":
									pass
								elif detail['Encryption'] == "wep":
									passphrase = ''
									selected_key = ''
									securitykey = ''
									displayinputlabel("key")
									drawkeyboard("wep")
									getinput("wep", "key", ssid)
								else:
									passphrase = ''
									selected_key = ''
									securitykey = ''
									displayinputlabel("key")
									drawkeyboard("qwertyNormal")
									getinput("qwertyNormal", "key", ssid)

					if active_menu == "saved": # Allow us to edit the existing key
						ssid = ''

						for network, detail in uniq.iteritems():
							position = str(wirelessmenu.get_position()+1)
							if str(detail['menu']) == position:
								ssid = network
								passphrase = uniq[network]['Key']
								encryption = uniq[network]['Encryption'].upper()
								if uniq[network]['Encryption'] == "none":
									pass
								elif uniq[network]['Encryption'] == "wep":
									passphrase = ''
									selected_key = ''
									securitykey = ''
									encryption = "WEP-40"
									displayinputlabel("key")
									drawkeyboard("wep")
									getinput("wep", "key", ssid)
								else:
									passphrase = ''
									selected_key = ''
									securitykey = ''
									displayinputlabel("key")
									drawkeyboard("qwertyNormal")
									getinput("qwertyNormal", "key", ssid)


		pygame.display.update()