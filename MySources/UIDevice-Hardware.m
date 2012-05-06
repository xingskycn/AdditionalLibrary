/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

// Thanks to Emanuele Vulcano, Kevin Ballard/Eridius, Ryandjohnson, Matt Brown, etc.
// TTD:  - Bluetooth?  Screen pixels? Dot pitch? Accelerometer? GPS enabled/disabled

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "UIDevice-Hardware.h"

@implementation UIDevice (Hardware)

/*
 Platforms
 
 iFPGA ->		??

 iPhone1,1 ->	iPhone 1G
 iPhone1,2 ->	iPhone 3G
 iPhone2,1 ->	iPhone 3GS
 iPhone3,1 ->	iPhone 4G/AT&T
 iPhone3,2 ->	iPhone 4G/Other Carrier
 iPhone3,3 ->	iPhone 4G/Other Carrier
 iPhone4,1 ->	??

 iPod1,1   -> iPod touch 1G 
 iPod2,1   -> iPod touch 2G 
 iPod2,2   -> iPod touch 2.5G
 iPod3,1   -> iPod touch 3G
 iPod4,1   -> iPod touch 4G
 iPod5,1   ->
 
 iPad1,1   -> iPad 1G, WiFi
 iPad1,?   -> iPad 1G, 3G <- needs 3G owner to test
 iPad2,1   -> iPad 2G

 i386 -> iPhone Simulator
*/


#pragma mark sysctlbyname utils
- (NSString *) getSysInfoByName:(char *)typeSpecifier
{
	size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = malloc(size);
	sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
	NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
	free(answer);
	return results;
}

- (NSString *) platform
{
	return [self getSysInfoByName:"hw.machine"];
}


// Thanks, Atomicbird
- (NSString *) hwmodel
{
	return [self getSysInfoByName:"hw.model"];
}

#pragma mark sysctl utils
- (NSUInteger) getSysInfo: (uint) typeSpecifier
{
	size_t size = sizeof(int);
	int results;
	int mib[2] = {CTL_HW, typeSpecifier};
	sysctl(mib, 2, &results, &size, NULL, 0);
	return (NSUInteger) results;
}

- (NSUInteger) cpuFrequency
{
	return [self getSysInfo:HW_CPU_FREQ];
}

- (NSUInteger) busFrequency
{
	return [self getSysInfo:HW_BUS_FREQ];
}

- (NSUInteger) totalMemory
{
	return [self getSysInfo:HW_PHYSMEM];
}

- (NSUInteger) userMemory
{
	return [self getSysInfo:HW_USERMEM];
}

- (NSUInteger) maxSocketBufferSize
{
	return [self getSysInfo:KIPC_MAXSOCKBUF];
}

#pragma mark file system -- Thanks Joachim Bean!

- (NSNumber *) totalDiskSpace
{
	NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
	return [fattributes objectForKey:NSFileSystemSize];
}

- (NSNumber *) freeDiskSpace
{
	NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
	return [fattributes objectForKey:NSFileSystemFreeSize];
}

#pragma mark platform type and name utils
- (NSUInteger) platformType
{
	NSString *platform = [self platform];
	// if ([platform isEqualToString:@"XX"])			return UIDeviceUnknown;
	
	if ([platform isEqualToString:@"iFPGA"])		return UIDeviceIFPGA;

	if ([platform isEqualToString:@"iPhone1,1"])	return UIDevice1GiPhone;
	if ([platform isEqualToString:@"iPhone1,2"])	return UIDevice3GiPhone;
	if ([platform isEqualToString:@"iPhone2,1"])	return UIDevice3GSiPhone;
	if ([platform hasPrefix:@"iPhone3"])			return UIDevice4GiPhone;
	
	if ([platform isEqualToString:@"iPod1,1"])   return UIDevice1GiPod;
	if ([platform isEqualToString:@"iPod2,1"])   return UIDevice2GiPod;
	if ([platform isEqualToString:@"iPod2,2"])   return UIDevice2GPlusiPod;
	if ([platform isEqualToString:@"iPod3,1"])   return UIDevice3GiPod;
	if ([platform isEqualToString:@"iPod4,1"])   return UIDevice4GiPod;
		
	if ([platform isEqualToString:@"iPad1,1"])   return UIDevice1GiPad;
	// if ([platform isEqualToString:@"iPad2,1"])   return UIDevice2GiPad;
	
	if ([platform isEqualToString:@"iTV1,1"])   return UIDevice1GiTV;
	
	/*
	 MISSING A SOLUTION HERE TO DATE TO DIFFERENTIATE iPAD and iPAD 3G.... SORRY!
	 */

	if ([platform hasPrefix:@"iPhone"]) return UIDeviceUnknowniPhone;
	if ([platform hasPrefix:@"iPod"]) return UIDeviceUnknowniPod;
	if ([platform hasPrefix:@"iPad"]) return UIDeviceUnknowniPad;
	if ([platform hasPrefix:@"iTV"]) return UIDeviceUnknowniTV;
	
	if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"]) // thanks Jordan Breeding
	{
		if ([[UIScreen mainScreen] bounds].size.width < 768)
			return UIDeviceiPhoneSimulatoriPhone;
		else 
			return UIDeviceiPhoneSimulatoriPad;

		return UIDeviceiPhoneSimulator;
	}
	return UIDeviceUnknown;
}

- (NSString *) platformString
{
	switch ([self platformType])
	{
		case UIDevice1GiPhone: return IPHONE_1G_NAMESTRING;
		case UIDevice3GiPhone: return IPHONE_3G_NAMESTRING;
		case UIDevice3GSiPhone:	return IPHONE_3GS_NAMESTRING;
		case UIDevice4GiPhone:	return IPHONE_4G_NAMESTRING;
		case UIDeviceUnknowniPhone: return IPHONE_UNKNOWN_NAMESTRING;
		
		case UIDevice1GiPod: return IPOD_1G_NAMESTRING;
		case UIDevice2GiPod: return IPOD_2G_NAMESTRING;
		case UIDevice3GiPod: return IPOD_3G_NAMESTRING;
		case UIDevice4GiPod: return IPOD_4G_NAMESTRING;
		case UIDeviceUnknowniPod: return IPOD_UNKNOWN_NAMESTRING;
			
		case UIDevice1GiPad : return IPAD_1G_NAMESTRING;
			
		case UIDevice1GiTV : return ITV_1G_NAMESTRING;
			
		case UIDeviceiPhoneSimulator: return IPHONE_SIMULATOR_NAMESTRING;
		case UIDeviceiPhoneSimulatoriPhone: return IPHONE_SIMULATOR_IPHONE_NAMESTRING;
		case UIDeviceiPhoneSimulatoriPad: return IPHONE_SIMULATOR_IPAD_NAMESTRING;
			
		case UIDeviceIFPGA: return IFPGA_NAMESTRING;
			
		default: return IPOD_FAMILY_UNKNOWN_DEVICE;
	}
}

#pragma mark  platform capabilities
- (NSUInteger) platformCapabilities
{
	switch ([self platformType])
	{
		case UIDevice1GiPhone: 
			return 
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 UIDeviceCommoSupportsTelephony |
			 UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth | // M68.plist says YES for this
			 // UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike 
			 // UIDeviceSupportsAccessibility |
			 // UIDeviceSupportsVoiceOver |
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch
			 );
		case UIDevice3GiPhone: 
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 UIDeviceCommoSupportsTelephony |
			 UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike 
			 // UIDeviceSupportsAccessibility |
			 // UIDeviceSupportsVoiceOver |
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch
			 );
			
		case UIDevice3GSiPhone: 
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 UIDeviceCamerasSupportsStillCamera |
			 UIDeviceCamerasSupportsAutofocusCamera |
			 UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 UIDeviceCommoSupportsTelephony |
			 UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 UIDeviceSupportsOPENGLES2 |
			 UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl |
			 UIDeviceSupportsEnhancedMultitouch
			 );
		case UIDevice4GiPhone: 
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 UIDeviceSensorsSupportsGyro |
			 UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 UIDeviceCamerasSupportsStillCamera |
			 UIDeviceCamerasSupportsAutofocusCamera |
			 UIDeviceCamerasSupportsVideoCamera |
			 UIDeviceCamerasSupportsFrontCamera |
			 UIDeviceCamerasSupportsBackLED |
			 UIDeviceCommoSupportsTelephony |
			 UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 UIDeviceSupportsOPENGLES2 |
			 UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl |
			 UIDeviceSupportsEnhancedMultitouch
			 );			
			
		case UIDeviceUnknowniPhone: return 0;
			
		case UIDevice1GiPod: 
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 // UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 // UIDeviceCommoSupportsBluetooth |
			 // UIDeviceCommoSupportsPeerToPeer |
			 // UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 UIDeviceAudioSupportsPiezoClicker |
			 // UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 // UIDeviceSupportsNike |
			 // UIDeviceSupportsAccessibility |
			 // UIDeviceSupportsVoiceOver |
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch
			 );			
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 // UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 // UIDeviceSupportsNike |
			 // UIDeviceSupportsAccessibility |
			 // UIDeviceSupportsVoiceOver |
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch
			 
			);
			
		case UIDevice2GiPod: 
		case UIDevice2GPlusiPod:
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 // UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 // UIDeviceSupportsNike |
			 // UIDeviceSupportsAccessibility |
			 // UIDeviceSupportsVoiceOver |
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch
			 
			 );
			
			
		case UIDevice3GiPod: 
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 // UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl
			 // UIDeviceSupportsEnhancedMultitouch			 
			 );
			
		case UIDevice4GiPod: // guessing
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 // UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl
			 // UIDeviceSupportsEnhancedMultitouch			 
			 );
		case UIDeviceUnknowniPod:  return 0;
			
		case UIDevice1GiPad: // cannot distinguish between wifi and 3g here, I'm afraid
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS | // available on 3G -- still working on fix here
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl |
			 UIDeviceSupportsEnhancedMultitouch			 
			 );
			
		case UIDevice2GiPad: // guesswork
			return
			(
			 UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 UIDeviceSensorsSupportsMagnetometer |
			 UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 UIDeviceCommoSupportsBluetooth |
			 UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 UIDeviceAudioSupportsHardwareVolumeButtons |
			 UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver |
			 UIDeviceSupportsVoiceControl |
			 UIDeviceSupportsEnhancedMultitouch	
			 );

		case UIDeviceiPhoneSimulator: 
			return
			(
			 // UIDeviceSensorsSupportsAccelerometer |
			 // UIDeviceSensorsSupportsGyro |
			 // UIDeviceSensorsSupportsMagnetometer |
			 // UIDeviceSensorsSupportsBrightnessSensor |
			 // UIDeviceSensorsSupportsBuiltInProximitySensor |
			 UIDeviceSensorsSupportsBuiltInMicrophone |
			 UIDeviceSensorsSupportsExternalMicrophone |
			 // UIDeviceSensorsSupportsDualMicNoiseSuppression |
			 // UIDeviceCamerasSupportsStillCamera |
			 // UIDeviceCamerasSupportsAutofocusCamera |
			 // UIDeviceCamerasSupportsVideoCamera |
			 // UIDeviceCamerasSupportsFrontCamera |
			 // UIDeviceCamerasSupportsBackLED |
			 // UIDeviceCommoSupportsTelephony |
			 // UIDeviceCommoSupportsSMS |
			 UIDeviceCommoSupportsWifi |
			 // UIDeviceCommoSupportsBluetooth |
			 // UIDeviceCommoSupportsPeerToPeer |
			 UIDeviceAudioSupportsBuiltInSpeaker |
			 // UIDeviceAudioSupportsVibration |
			 // UIDeviceAudioSupportsPiezoClicker |
			 // UIDeviceAudioSupportsHardwareVolumeButtons |
			 // UIDeviceAudioSupportsEncodeAAC |
			 UIDeviceSupportsLocationServices |
			 // UIDeviceSupportsGPS |
			 UIDeviceSupportsOPENGLES1_1 |
			 // UIDeviceSupportsOPENGLES2 |
			 // UIDeviceSupportsARMV7 |
			 // UIDeviceSupportsNike |
			 UIDeviceSupportsAccessibility |
			 UIDeviceSupportsVoiceOver
			 // UIDeviceSupportsVoiceControl |
			 // UIDeviceSupportsEnhancedMultitouch	
			 );
		default: return 0;
	}
}

// Courtesy of Danny Sung <dannys@mail.com>
- (BOOL) platformHasCapability:(NSUInteger)capability 
{
    if( ([self platformCapabilities] & capability) == capability )
        return YES;
    return NO;
}

- (NSArray *) capabilityArray
{
	NSUInteger flags = [self platformCapabilities];
	NSMutableArray *array = [NSMutableArray array];
	
	if (flags & UIDeviceSensorsSupportsAccelerometer) [array addObject:@"Accelerometer"];
	if (flags & UIDeviceSensorsSupportsGyro) [array addObject:@"Gyro"];
	if (flags & UIDeviceSensorsSupportsMagnetometer) [array addObject:@"Magnetometer"];
	if (flags & UIDeviceSensorsSupportsBrightnessSensor) [array addObject:@"Brightness Sesnsor"];
	if (flags & UIDeviceSensorsSupportsBuiltInProximitySensor) [array addObject:@"Proximity Sensor"];
	if (flags & UIDeviceSensorsSupportsBuiltInProximitySensor) [array addObject:@"Proximity Sensor"];
	if (flags & UIDeviceSensorsSupportsBuiltInProximitySensor) [array addObject:@"Proximity Sensor"];
	if (flags & UIDeviceSensorsSupportsBuiltInMicrophone) [array addObject:@"Built-in Microphone"];
	if (flags & UIDeviceSensorsSupportsExternalMicrophone) [array addObject:@"External Microphone Support"];
	if (flags & UIDeviceSensorsSupportsDualMicNoiseSuppression) [array addObject:@"Dual Mic Noise Suppression"];
	
	if (flags & UIDeviceCamerasSupportsStillCamera) [array addObject:@"Still Camera"];
	if (flags & UIDeviceCamerasSupportsAutofocusCamera) [array addObject:@"Autofocus Camera"];
	if (flags & UIDeviceCamerasSupportsVideoCamera) [array addObject:@"Video Camera"];
	if (flags & UIDeviceCamerasSupportsFrontCamera) [array addObject:@"Front Camera"];
	if (flags & UIDeviceCamerasSupportsBackLED) [array addObject:@"Back LED"];

	if (flags & UIDeviceCommoSupportsTelephony) [array addObject:@"Telephony"];
	if (flags & UIDeviceCommoSupportsSMS) [array addObject:@"SMS"];
	if (flags & UIDeviceCommoSupportsWifi) [array addObject:@"Wi-Fi"];
	if (flags & UIDeviceCommoSupportsBluetooth) [array addObject:@"Bluetooth"];
	if (flags & UIDeviceCommoSupportsPeerToPeer) [array addObject:@"Peer to Peer"];

	if (flags & UIDeviceAudioSupportsBuiltInSpeaker) [array addObject:@"Built-in Speaker"];
	if (flags & UIDeviceAudioSupportsVibration) [array addObject:@"Vibration"];
	if (flags & UIDeviceAudioSupportsPiezoClicker) [array addObject:@"Piezo Clicker"];
	if (flags & UIDeviceAudioSupportsHardwareVolumeButtons) [array addObject:@"Hardware Volume Buttons"];
	if (flags & UIDeviceAudioSupportsEncodeAAC) [array addObject:@"AAC Encoding"];

	if (flags & UIDeviceSupportsLocationServices) [array addObject:@"Location Services"];
	if (flags & UIDeviceSupportsGPS) [array addObject:@"GPS"];
	
	if (flags & UIDeviceSupportsOPENGLES1_1) [array addObject:@"OpenGLES 1.1"];
	if (flags & UIDeviceSupportsOPENGLES2) [array addObject:@"OpenGLES 2.x"];
	
	if (flags & UIDeviceSupportsNike) [array addObject:@"Nike Support"];

	if (flags & UIDeviceSupportsAccessibility) [array addObject:@"Accessibility"];
	if (flags & UIDeviceSupportsVoiceOver) [array addObject:@"VoiceOver"];
	if (flags & UIDeviceSupportsVoiceControl) [array addObject:@"Voice Control"];

	if (flags & UIDeviceSupportsEnhancedMultitouch) [array addObject:@"Enhanced Multitouch"];
	
	return array;
}

#pragma mark MAC addy
// Return the local MAC addy
// Courtesy of FreeBSD hackers email list
// Accidentally munged during previous update. Fixed thanks to mlamb.
- (NSString *) macaddress
{
	int					mib[6];
	size_t				len;
	char				*buf;
	unsigned char		*ptr;
	struct if_msghdr	*ifm;
	struct sockaddr_dl	*sdl;
	
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
	
	if ((mib[5] = if_nametoindex("en0")) == 0) {
		printf("Error: if_nametoindex error\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
		printf("Error: sysctl, take 1\n");
		return NULL;
	}
	
	if ((buf = malloc(len)) == NULL) {
		printf("Could not allocate memory. error!\n");
		return NULL;
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		printf("Error: sysctl, take 2");
		return NULL;
	}
	
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	// NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	free(buf);
	return [outstring uppercaseString];
}

- (NSString *) platformCode
{
	switch ([self platformType])
	{
		case UIDevice1GiPhone: return @"M68";
		case UIDevice3GiPhone: return @"N82";
		case UIDevice3GSiPhone:	return @"N88";
		case UIDevice4GiPhone: return @"N89";
		case UIDeviceUnknowniPhone: return IPHONE_UNKNOWN_NAMESTRING;
			
		case UIDevice1GiPod: return @"N45";
		case UIDevice2GiPod: return @"N72";
		case UIDevice3GiPod: return @"N18"; 
		case UIDevice4GiPod: return @"N80";
		case UIDeviceUnknowniPod: return IPOD_UNKNOWN_NAMESTRING;
			
		case UIDevice1GiPad: return @"K48";
		// case UIDevice2GiPad: return nil;
		case UIDeviceUnknowniPad: return IPAD_UNKNOWN_NAMESTRING;
			
		case UIDeviceUnknowniTV: return ITV_UNKNOWN_NAMESTRING;
			
		case UIDeviceiPhoneSimulator: return IPHONE_SIMULATOR_NAMESTRING;
			
		default: return IPOD_FAMILY_UNKNOWN_DEVICE;
	}
}

// Illicit Bluetooth check -- cannot be used in App Store
/* Class  btclass = NSClassFromString(@"GKBluetoothSupport");
if ([btclass respondsToSelector:@selector(bluetoothStatus)]) 
{
	printf("BTStatus %d\n", ((int)[btclass performSelector:@selector(bluetoothStatus)] & 1) != 0);
	bluetooth = ((int)[btclass performSelector:@selector(bluetoothStatus)] & 1) != 0;
	printf("Bluetooth %s enabled\n", bluetooth ? "is" : "isn't");
}*/
@end