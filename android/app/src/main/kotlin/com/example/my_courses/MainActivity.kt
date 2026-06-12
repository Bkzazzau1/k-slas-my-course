package com.example.my_courses

import android.content.Context
import android.hardware.display.DisplayManager
import android.hardware.usb.UsbManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "kasu_integrity_shield/hardware"
    private var hardwareChannel: MethodChannel? = null

    private val audioRouteCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
            publishAudioRouteState()
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
            publishAudioRouteState()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        hardwareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        hardwareChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessoryConnected" -> {
                    result.success(checkUnauthorizedAccessories().isNotEmpty())
                }
                "checkUnauthorizedPeripherals" -> {
                    result.success(checkUnauthorizedAccessories())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.registerAudioDeviceCallback(audioRouteCallback, null)
        }
        publishAudioRouteState()
    }

    override fun onStop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.unregisterAudioDeviceCallback(audioRouteCallback)
        }
        super.onStop()
    }

    private fun publishAudioRouteState() {
        val hasHeadset = checkUnauthorizedAccessories().any {
            it == "wired_headset" || it == "bluetooth_headset" || it == "usb_audio"
        }
        runOnUiThread {
            hardwareChannel?.invokeMethod(
                "audioRouteChanged",
                mapOf("isHeadset" to hasHeadset)
            )
        }
    }

    private fun checkUnauthorizedAccessories(): List<String> {
        val detections = mutableSetOf<String>()

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

            for (device in devices) {
                when (device.type) {
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> detections.add("wired_headset")

                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> detections.add("bluetooth_headset")

                    AudioDeviceInfo.TYPE_USB_DEVICE,
                    AudioDeviceInfo.TYPE_USB_HEADSET -> detections.add("usb_audio")
                }
            }
        } else {
            @Suppress("DEPRECATION")
            if (audioManager.isWiredHeadsetOn) {
                detections.add("wired_headset")
            }
            @Suppress("DEPRECATION")
            if (audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn) {
                detections.add("bluetooth_headset")
            }
        }

        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        if (usbManager.deviceList.isNotEmpty()) {
            detections.add("usb_device")
        }

        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        if (displayManager.displays.size > 1) {
            detections.add("secondary_display")
        }

        return detections.toList()
    }
}
