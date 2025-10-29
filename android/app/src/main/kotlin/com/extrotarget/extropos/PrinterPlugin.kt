package com.extrotarget.extropos

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.RequiresApi
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDeviceConnection
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream
import java.net.Socket
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.bluetooth.BluetoothManager
import java.util.*

// Import ESCPOS Thermal Printer SDK
import com.dantsu.escposprinter.EscPosPrinter
import com.dantsu.escposprinter.connection.DeviceConnection
import com.dantsu.escposprinter.connection.bluetooth.BluetoothConnection
import com.dantsu.escposprinter.connection.tcp.TcpConnection
import com.dantsu.escposprinter.connection.usb.UsbConnection
import com.dantsu.escposprinter.textparser.PrinterTextParserImg

class PrinterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var activity: Activity? = null
    private var usbAttachReceiver: BroadcastReceiver? = null
    private val ACTION_USB_PERMISSION = "com.extrotarget.extropos.USB_PERMISSION"

    private fun postLog(message: String) {
        try {
            Log.d("PrinterPlugin", message)
            // Forward to Dart side for in-app debugging if handler is registered
            try {
                channel.invokeMethod("printerLog", mapOf("message" to message))
            } catch (ie: Exception) {
                // ignore if Dart handler not ready
            }
        } catch (e: Exception) {
            // ignore logging issues
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.extrotarget.extropos/printer")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware methods to request USB permission if needed
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity

        // Listen for USB device attachment to auto-request permission for printers
        try {
            if (usbAttachReceiver == null) {
                usbAttachReceiver = object : BroadcastReceiver() {
                    override fun onReceive(ctx: Context?, intent: Intent?) {
                        if (intent == null) return
                        when (intent.action) {
                            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                                }
                                if (device != null) {
                                    postLog("USB ATTACHED: id=${device.deviceId} vid=${device.vendorId} pid=${device.productId} name=${device.deviceName} product=${device.productName} mfg=${device.manufacturerName}")
                                    
                                    // Check if likely a printer for logging
                                    val likelyPrinter = try {
                                        isPrinterDevice(device) ||
                                        (device.productName?.lowercase()?.contains("printer") == true) ||
                                        (device.productName?.lowercase()?.contains("pos") == true) ||
                                        (device.productName?.lowercase()?.contains("receipt") == true)
                                    } catch (_: Exception) { false }

                                    if (likelyPrinter) {
                                        postLog("USB ATTACHED: Detected as likely printer")
                                    } else {
                                        postLog("USB ATTACHED: Not obviously a printer, but requesting permission anyway")
                                    }
                                    
                                    // Request permission for ALL USB devices (user can decline if not needed)
                                    try {
                                        val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                                        if (!usbManager.hasPermission(device)) {
                                            val pi = PendingIntent.getBroadcast(
                                                context, 
                                                0, 
                                                Intent(ACTION_USB_PERMISSION), 
                                                PendingIntent.FLAG_IMMUTABLE
                                            )
                                            postLog("USB ATTACHED: requesting permission for attached device")
                                            usbManager.requestPermission(device, pi)
                                        } else {
                                            postLog("USB ATTACHED: permission already granted for device")
                                        }
                                    } catch (e: Exception) {
                                        Log.e("PrinterPlugin", "USB attach handling error", e)
                                    }
                                }
                            }
                            UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                                }
                                if (device != null) {
                                    postLog("USB DETACHED: id=${device.deviceId} vid=${device.vendorId} pid=${device.productId} name=${device.deviceName}")
                                }
                            }
                        }
                    }
                }

                val filter = IntentFilter().apply {
                    addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                    addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
                }
                context.registerReceiver(usbAttachReceiver, filter)
                postLog("USB attach receiver registered")
            }
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "Failed to register USB attach receiver", e)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
        activity = null
        // Unregister attach receiver
        try {
            usbAttachReceiver?.let {
                context.unregisterReceiver(it)
                postLog("USB attach receiver unregistered")
            }
        } catch (_: Exception) {} finally { usbAttachReceiver = null }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
    postLog("onMethodCall: ${call.method} args=${call.arguments}")
        when (call.method) {
            "discoverPrinters" -> discoverPrinters(result)
            "requestUsbPermission" -> requestUsbPermission(call, result)
            "printReceipt" -> printReceipt(call, result)
            "printOrder" -> printOrder(call, result)
            "testPrint" -> testPrint(call, result)
            "checkPrinterStatus" -> checkPrinterStatus(call, result)
            "printViaExternalService" -> printViaExternalService(call, result)
            else -> result.notImplemented()
        }
    }

    private fun printViaExternalService(call: MethodCall, result: Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
            val paperSize = args["paperSize"] as? String
            @Suppress("UNCHECKED_CAST")
            val data = (args["receiptData"] ?: args["orderData"]) as? Map<String, Any>
            val title = data?.get("title") as? String ?: "RECEIPT"
            val content = data?.get("content") as? String ?: ""
            val timestamp = data?.get("timestamp") as? String ?: ""

            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }

            val sb = StringBuilder()
            sb.append(title).append('\n')
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append(content).append('\n')
            if (timestamp.isNotEmpty()) {
                sb.append("Time: ").append(timestamp).append('\n')
            }
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append("Thank you!\n")

            val text = sb.toString()

            // Prefer ESCPrint Service if installed
            val targetPackage = "com.loopedlabs.escposprintservice"
            val pm = context.packageManager

            // Build base share intent
            val baseIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TITLE, title)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            var launched = false
            try {
                val targeted = Intent(baseIntent).apply { setPackage(targetPackage) }
                if (targeted.resolveActivity(pm) != null) {
                    context.startActivity(targeted)
                    launched = true
                    postLog("EXTERNAL PRINT: Launched ESCPrint Service directly")
                }
            } catch (_: Exception) { /* ignore and fallback */ }

            if (!launched) {
                val chooser = Intent.createChooser(baseIntent, "Print receipt with…").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(chooser)
                postLog("EXTERNAL PRINT: Launched chooser for external printer service")
            }

            result.success(true)
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "External print error", e)
            result.error("EXTERNAL_PRINT_FAILED", e.message, null)
        }
    }

    private fun requestUsbPermission(call: MethodCall, result: Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val connectionDetails = call.arguments as? Map<String, Any>
            val usbDeviceId = connectionDetails?.get("usbDeviceId") as? String
            val platformId = connectionDetails?.get("platformSpecificId") as? String

            val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

            var targetDevice: UsbDevice? = null
            for ((name, device) in usbManager.deviceList) {
                if (usbDeviceId != null) {
                    try {
                        if (matchesUsbDevice(device, usbDeviceId)) {
                            targetDevice = device
                            break
                        }
                    } catch (_: Exception) {}
                }
                if (platformId != null) {
                    if (device.deviceName == platformId) {
                        targetDevice = device
                        break
                    }
                }
            }

            if (targetDevice == null) {
                Log.d("PrinterPlugin", "USB: device not found for permission request")
                result.success(false)
                return
            }

            if (usbManager.hasPermission(targetDevice)) {
                result.success(true)
                return
            }

            val ACTION_USB_PERMISSION = "com.extrotarget.extropos.USB_PERMISSION"
            val pi = PendingIntent.getBroadcast(
                context, 
                0, 
                Intent(ACTION_USB_PERMISSION), 
                PendingIntent.FLAG_IMMUTABLE
            )

            val latch = java.util.concurrent.CountDownLatch(1)
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    if (intent == null) return
                    if (intent.action == ACTION_USB_PERMISSION) {
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        Log.d("PrinterPlugin", "USB permission result: $granted")
                        latch.countDown()
                    }
                }
            }

            val filter = IntentFilter(ACTION_USB_PERMISSION)
            context.registerReceiver(receiver, filter)
            usbManager.requestPermission(targetDevice, pi)

            try {
                latch.await(4, java.util.concurrent.TimeUnit.SECONDS)
            } catch (ie: InterruptedException) {
            }

            try { context.unregisterReceiver(receiver) } catch (e: Exception) {}

            val granted = usbManager.hasPermission(targetDevice)
            Log.d("PrinterPlugin", "USB: final permission state: $granted")
            result.success(granted)
        } catch (e: Exception) {
            Log.d("PrinterPlugin", "requestUsbPermission error: ${e.message}")
            result.error("USB_PERMISSION_ERROR", "${e.message}", null)
        }
    }

    private fun discoverPrinters(result: Result) {
        try {
            val printers = mutableListOf<Map<String, Any>>()

            // Discover USB printers
            val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
            val usbDevices = usbManager.deviceList
            
            postLog("USB Discovery: Found ${usbDevices.size} USB devices")
            
            // List ALL USB devices - let user select even if not obviously a printer
            for ((name, device) in usbDevices) {
                val vidHex = String.format("%04X", device.vendorId)
                val pidHex = String.format("%04X", device.productId)
                
                // Log every device for debugging
                postLog("USB Device: $name, ID=${device.deviceId}, VID=$vidHex, PID=$pidHex, Class=${device.deviceClass}, InterfaceCount=${device.interfaceCount}, Product=${device.productName}, Mfg=${device.manufacturerName}")
                
                // Check if likely a printer for better labeling
                val isPrinter = isPrinterDevice(device)
                val mightBePrinter = device.productName?.lowercase()?.contains("printer") == true ||
                                     device.productName?.lowercase()?.contains("pos") == true ||
                                     device.productName?.lowercase()?.contains("receipt") == true ||
                                     device.manufacturerName?.lowercase()?.contains("epson") == true ||
                                     device.manufacturerName?.lowercase()?.contains("star") == true ||
                                     device.manufacturerName?.lowercase()?.contains("citizen") == true
                
                val deviceLabel = if (isPrinter || mightBePrinter) "✓ Printer" else "USB Device"
                postLog("USB: $deviceLabel - $name")
                
                printers.add(mutableMapOf<String, Any>().apply {
                    put("id", "usb_${device.deviceId}")
                    put("name", getDeviceName(device))
                    put("connectionType", "usb")
                    // Use VID:PID as stable identifier
                    put("usbDeviceId", "$vidHex:$pidHex")
                    put("platformSpecificId", name)
                    put("printerType", "receipt")
                    put("status", "offline")
                    put("modelName", (device.productName ?: device.deviceName ?: "USB Device") + " (VID:$vidHex PID:$pidHex)")
                })
            }
            
            postLog("USB Discovery: Found ${printers.size} USB printers")

            // Discover Bluetooth printers (if Bluetooth is available)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                discoverBluetoothPrinters(printers)
            }

            result.success(printers)
        } catch (e: Exception) {
            postLog("Discovery error: ${e.message}")
            result.error("DISCOVERY_FAILED", "Failed to discover printers: ${e.message}", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun discoverBluetoothPrinters(printers: MutableList<Map<String, Any>>) {
        try {
            val bluetoothAdapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                bluetoothManager.adapter
            } else {
                @Suppress("DEPRECATION")
                BluetoothAdapter.getDefaultAdapter()
            }
            if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                val pairedDevices = bluetoothAdapter.bondedDevices
                for (device in pairedDevices) {
                    // Check if device name suggests it's a printer
                    if (isBluetoothPrinter(device)) {
                        printers.add(mutableMapOf<String, Any>().apply {
                            put("id", "bt_${device.address.replace(":", "")}")
                            put("name", device.name ?: "Unknown Bluetooth Printer")
                            put("connectionType", "bluetooth")
                            put("bluetoothAddress", device.address)
                            put("platformSpecificId", device.address)
                            put("printerType", "receipt") // Default type
                            put("status", "offline")
                            put("modelName", device.name ?: "Unknown Bluetooth Printer")
                        })
                    }
                }
            }
        } catch (e: Exception) {
            // Bluetooth discovery failed, continue without Bluetooth printers
        }
    }

    private fun printReceipt(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        @Suppress("UNCHECKED_CAST")
        val receiptData = args["receiptData"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "receiptData required", null)
        val paperSize = args["paperSize"] as? String

        try {
            postLog("printReceipt: printerId=$printerId printerType=$printerType paperSize=$paperSize connectionDetails=$connectionDetails")
            val success = when (printerType) {
                "network" -> printToNetworkPrinter(connectionDetails, receiptData, paperSize)
                "usb" -> printToUsbPrinter(connectionDetails, receiptData, paperSize)
                "bluetooth" -> printToBluetoothPrinter(connectionDetails, receiptData, paperSize)
                else -> false
            }
            postLog("printReceipt: result=$success")
            result.success(success)
        } catch (e: Exception) {
            postLog("printReceipt error: ${e.message}")
            result.error("PRINT_FAILED", "Failed to print receipt: ${e.message}", null)
        }
    }

    private fun printOrder(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        @Suppress("UNCHECKED_CAST")
        val orderData = args["orderData"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "orderData required", null)
        val paperSize = args["paperSize"] as? String

        try {
            val success = when (printerType) {
                "network" -> printToNetworkPrinter(connectionDetails, orderData, paperSize)
                "usb" -> printToUsbPrinter(connectionDetails, orderData, paperSize)
                "bluetooth" -> printToBluetoothPrinter(connectionDetails, orderData, paperSize)
                else -> false
            }
            result.success(success)
        } catch (e: Exception) {
            result.error("PRINT_FAILED", "Failed to print order: ${e.message}", null)
        }
    }

    private fun testPrint(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        val paperSize = args["paperSize"] as? String

        val testData = mapOf(
            "title" to "TEST PRINT",
            "content" to "This is a test print from Flutter POS\n\nPrinter ID: $printerId\nConnection Type: $printerType\n\nTest completed successfully!",
            "timestamp" to System.currentTimeMillis().toString()
        )

        try {
            val success = when (printerType) {
                "network" -> printToNetworkPrinter(connectionDetails, testData, paperSize)
                "usb" -> printToUsbPrinter(connectionDetails, testData, paperSize)
                "bluetooth" -> printToBluetoothPrinter(connectionDetails, testData, paperSize)
                else -> false
            }
            result.success(success)
        } catch (e: Exception) {
            result.error("TEST_PRINT_FAILED", "Test print failed: ${e.message}", null)
        }
    }

    private fun checkPrinterStatus(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)

        try {
            val status = when (printerType) {
                "network" -> checkNetworkPrinterStatus(connectionDetails)
                "usb" -> checkUsbPrinterStatus(connectionDetails)
                "bluetooth" -> checkBluetoothPrinterStatus(connectionDetails)
                else -> "offline"
            }
            result.success(status)
        } catch (e: Exception) {
            result.success("error")
        }
    }

    // Network printing implementation - using raw socket for reliability
    @Suppress("UNCHECKED_CAST")
    private fun printToNetworkPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        val ipAddress = connectionDetails["ipAddress"] as String
        val port = (connectionDetails["port"] as? Int) ?: 9100

        // Network I/O must run on background thread (Android StrictMode)
        val resultHolder = arrayOf(false)
        val latch = java.util.concurrent.CountDownLatch(1)

        Thread {
            var socket: Socket? = null
            try {
                postLog("NETWORK: connecting to $ipAddress:$port")
                
                // Use raw socket for full control and reliability
                socket = Socket()
                socket.connect(java.net.InetSocketAddress(ipAddress, port), 5000)
                socket.soTimeout = 10000
                
                // Get paper settings
                val charsPerLine = when (paperSize) {
                    "mm58" -> 32
                    "mm80" -> 48
                    else -> 48
                }
                
                // Build enhanced ESC/POS receipt
                val title = data["title"] as? String ?: "RECEIPT"
                val content = data["content"] as? String ?: ""
                val timestamp = data["timestamp"] as? String ?: ""
                
                val output = java.io.ByteArrayOutputStream()
                
                // ESC @ - Initialize printer
                output.write(0x1B)
                output.write(0x40)
                
                // Header section
                centerAlignBold(output)
                output.write(0x1D)
                output.write(0x21)
                output.write(0x11) // Double height + width
                output.write(title.toByteArray())
                output.write('\n'.code)
                resetFormatting(output)
                
                // Separator
                leftAlign(output)
                output.write(repeatChar('=', charsPerLine).toByteArray())
                output.write('\n'.code)
                
                // Parse and format content
                formatReceiptContent(output, content, charsPerLine)
                
                // Timestamp
                if (timestamp.isNotEmpty()) {
                    output.write('\n'.code)
                    output.write("Time: $timestamp\n".toByteArray())
                }
                
                // Bottom separator
                output.write(repeatChar('=', charsPerLine).toByteArray())
                output.write('\n'.code)
                output.write('\n'.code)
                
                // Footer
                centerAlign(output)
                output.write("Thank you!\n".toByteArray())
                output.write("Please come again\n".toByteArray())
                
                // Feed and cut
                output.write('\n'.code)
                output.write('\n'.code)
                output.write('\n'.code)
                output.write(0x1D)
                output.write(0x56)
                output.write(0x42)
                output.write(0x00)
                
                val escPosBytes = output.toByteArray()
                
                // Send to printer
                socket.getOutputStream().write(escPosBytes)
                socket.getOutputStream().flush()
                
                postLog("NETWORK: print successful, sent ${escPosBytes.size} bytes")
                resultHolder[0] = true
                
            } catch (e: Exception) {
                Log.e("PrinterPlugin", "NETWORK print error", e)
                postLog("NETWORK error: ${e.message}")
            } finally {
                try {
                    socket?.close()
                    postLog("NETWORK: socket closed")
                } catch (e: Exception) {
                    Log.e("PrinterPlugin", "NETWORK close error", e)
                }
                latch.countDown()
            }
        }.start()

        return try {
            latch.await(15, java.util.concurrent.TimeUnit.SECONDS)
            resultHolder[0]
        } catch (e: InterruptedException) {
            postLog("NETWORK: timeout")
            false
        }
    }

    // USB printing implementation using ESCPOS SDK
    @Suppress("UNCHECKED_CAST")
    private fun printToUsbPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        try {
            val usbManager = context.getSystemService(Context.USB_SERVICE) as android.hardware.usb.UsbManager

            // Try to locate device by usbDeviceId or platformSpecificId
            val usbDeviceId = (connectionDetails["usbDeviceId"] as? String)
            val platformId = (connectionDetails["platformSpecificId"] as? String)

            var targetDevice: UsbDevice? = null
            for ((_, device) in usbManager.deviceList) {
                if (usbDeviceId != null) {
                    try {
                        if (matchesUsbDevice(device, usbDeviceId)) {
                            targetDevice = device
                            break
                        }
                    } catch (_: Exception) {}
                }
                if (platformId != null) {
                    if (device.deviceName == platformId) {
                        targetDevice = device
                        break
                    }
                }
            }

            if (targetDevice == null) {
                postLog("USB: device not found on deviceList")
                return false
            }

            // If we don't have permission, request it and wait
            if (!usbManager.hasPermission(targetDevice)) {
                val ACTION_USB_PERMISSION = "com.extrotarget.extropos.USB_PERMISSION"
                val pi = PendingIntent.getBroadcast(
                    context, 
                    0, 
                    Intent(ACTION_USB_PERMISSION), 
                    PendingIntent.FLAG_IMMUTABLE
                )

                val latch = java.util.concurrent.CountDownLatch(1)
                val receiver = object : BroadcastReceiver() {
                    override fun onReceive(ctx: Context?, intent: Intent?) {
                        if (intent == null) return
                        if (intent.action == ACTION_USB_PERMISSION) {
                            val granted = intent.getBooleanExtra(android.hardware.usb.UsbManager.EXTRA_PERMISSION_GRANTED, false)
                            postLog("USB permission result: $granted")
                            latch.countDown()
                        }
                    }
                }

                val filter = IntentFilter(ACTION_USB_PERMISSION)
                context.registerReceiver(receiver, filter)
                usbManager.requestPermission(targetDevice, pi)

                try {
                    latch.await(4, java.util.concurrent.TimeUnit.SECONDS)
                } catch (ie: InterruptedException) {}

                try { context.unregisterReceiver(receiver) } catch (e: Exception) {}

                if (!usbManager.hasPermission(targetDevice)) {
                    postLog("USB: permission not granted")
                    return false
                }
            }

            // Use ESCPOS SDK's UsbConnection
            postLog("USB: creating connection using ESCPOS SDK")
            val usbConnection = UsbConnection(usbManager, targetDevice)
            
            try {
                // Get paper width
                val dpi = 203
                val widthMM = when (paperSize) {
                    "mm58" -> 58f
                    "mm80" -> 80f
                    else -> 80f
                }
                val charsPerLine = when (paperSize) {
                    "mm58" -> 32
                    "mm80" -> 48
                    else -> 48
                }
                
                // Build receipt text
                val receiptText = buildEscPosText(data, charsPerLine)
                
                // Create printer and print
                val printer = EscPosPrinter(
                    usbConnection,
                    dpi,
                    widthMM,
                    charsPerLine
                )
                
                printer.printFormattedTextAndCut(receiptText)
                postLog("USB: print successful via ESCPOS SDK")
                return true
            } finally {
                // Always disconnect to release USB connection
                try {
                    usbConnection.disconnect()
                    postLog("USB: connection closed")
                } catch (e: Exception) {
                    Log.e("PrinterPlugin", "USB disconnect error", e)
                }
            }

        } catch (e: Exception) {
            Log.e("PrinterPlugin", "USB print error", e)
            postLog("USB error: ${Log.getStackTraceString(e)}")
            return false
        }
    }

    // Bluetooth printing implementation using ESCPOS SDK
    @Suppress("UNCHECKED_CAST")
    private fun printToBluetoothPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return false
        }

        val address = connectionDetails["bluetoothAddress"] as String
        
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothManager.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
        
        if (adapter == null) {
            return false
        }

        var btConnection: BluetoothConnection? = null
        return try {
            val device = adapter.getRemoteDevice(address)
            postLog("BLUETOOTH: attempting connect to $address (${device.name}) using ESCPOS SDK")
            
            // Cancel discovery to improve connection reliability
            try { adapter.cancelDiscovery() } catch (_: Exception) {}
            
            // Create Bluetooth connection using ESCPOS SDK
            btConnection = BluetoothConnection(device)
            
            // Get paper width
            val dpi = 203
            val widthMM = when (paperSize) {
                "mm58" -> 58f
                "mm80" -> 80f
                else -> 80f
            }
            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }
            
            // Build receipt text
            val receiptText = buildEscPosText(data, charsPerLine)
            
            // Create printer and print
            val printer = EscPosPrinter(
                btConnection,
                dpi,
                widthMM,
                charsPerLine
            )
            
            printer.printFormattedTextAndCut(receiptText)
            postLog("BLUETOOTH: print successful via ESCPOS SDK to $address")
            true
            
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "BLUETOOTH print error", e)
            postLog("BLUETOOTH error: ${Log.getStackTraceString(e)}")
            false
        } finally {
            // Always disconnect to release Bluetooth connection
            try {
                btConnection?.disconnect()
                postLog("BLUETOOTH: connection closed")
            } catch (e: Exception) {
                Log.e("PrinterPlugin", "BLUETOOTH disconnect error", e)
            }
        }
    }

    // Status checking implementations
    @Suppress("UNCHECKED_CAST")
    private fun checkNetworkPrinterStatus(connectionDetails: Map<String, Any>): String {
        val ipAddress = connectionDetails["ipAddress"] as String
        val port = (connectionDetails["port"] as? Int) ?: 9100

        // Network I/O must run on background thread
        val resultHolder = arrayOf("offline")
        val latch = java.util.concurrent.CountDownLatch(1)

        Thread {
            try {
                val socket = Socket()
                try {
                    socket.connect(java.net.InetSocketAddress(ipAddress, port), 5000)
                    socket.soTimeout = 5000
                    resultHolder[0] = if (socket.isConnected) "online" else "offline"
                } catch (e: Exception) {
                    Log.d("PrinterPlugin", "checkNetworkPrinterStatus connect error: ${e.message}")
                    resultHolder[0] = "offline"
                } finally {
                    try { socket.close() } catch (_: Exception) {}
                }
            } catch (e: Exception) {
                resultHolder[0] = "offline"
            } finally {
                latch.countDown()
            }
        }.start()

        return try {
            latch.await(6, java.util.concurrent.TimeUnit.SECONDS)
            resultHolder[0]
        } catch (e: InterruptedException) {
            "offline"
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun checkUsbPrinterStatus(connectionDetails: Map<String, Any>): String {
        // USB status checking requires permission handling
        return "offline"
    }

    @Suppress("UNCHECKED_CAST")
    private fun checkBluetoothPrinterStatus(connectionDetails: Map<String, Any>): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return "offline"
        }

        val address = connectionDetails["bluetoothAddress"] as String
        
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothManager.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
        
        if (adapter == null) {
            return "offline"
        }

        return try {
            val device = adapter.getRemoteDevice(address)
            if (device.bondState == BluetoothDevice.BOND_BONDED) "online" else "offline"
        } catch (e: Exception) {
            "offline"
        }
    }

    /**
     * Build ESC/POS formatted text using the ESCPOS SDK's text formatting syntax.
     * 
     * The SDK supports tags like:
     * [C] - Center align
     * [L] - Left align
     * [R] - Right align
     * <b> - Bold
     * <u> - Underline
     * <font size='big'> - Large text
     * <font size='tall'> - Tall text
     * <font size='wide'> - Wide text
     */
    @Suppress("UNCHECKED_CAST")
    private fun buildEscPosText(data: Map<String, Any>, charsPerLine: Int): String {
        val title = data["title"] as? String ?: "RECEIPT"
        val content = data["content"] as? String ?: ""
        val timestamp = data["timestamp"] as? String ?: ""

        val sb = StringBuilder()
        
        // Header
        sb.append("[C]<b>") // Center align + bold
        sb.append("<font size='big'>")
        sb.append(title)
        sb.append("</font></b>\n")
        
        // Separator
        sb.append("[L]") // Left align
        sb.append(repeatChar('=', charsPerLine))
        sb.append("\n")
        
        // Format content intelligently
        val lines = content.split("\n")
        for (line in lines) {
            if (line.trim().isEmpty()) {
                sb.append("\n")
                continue
            }
            
            // Item lines with prices
            if (line.contains(" x ")) {
                sb.append(formatItemLineForSdk(line, charsPerLine))
            }
            // Total/subtotal lines
            else if (line.contains("RM") || line.contains("Subtotal:") || line.contains("Tax") || 
                     line.contains("Service") || line.contains("Total:") || 
                     line.contains("Payment:") || line.contains("Paid:") || line.contains("Change:")) {
                sb.append(formatTotalLineForSdk(line, charsPerLine))
            }
            else {
                sb.append(line)
                sb.append("\n")
            }
        }
        
        // Timestamp
        if (timestamp.isNotEmpty()) {
            sb.append("\n")
            sb.append("[L]<font size='small'>")
            sb.append("Time: $timestamp")
            sb.append("</font>\n")
        }
        
        // Footer separator
        sb.append(repeatChar('=', charsPerLine))
        sb.append("\n\n")
        
        // Thank you message
        sb.append("[C]")
        sb.append("Thank you!\n")
        sb.append("Please come again\n")
        sb.append("\n")
        
        return sb.toString()
    }

    private fun formatItemLineForSdk(line: String, charsPerLine: Int): String {
        try {
            val parts = line.split(" x ")
            if (parts.size < 2) return "$line\n"
            
            val itemName = parts[0].trim()
            val remaining = parts[1].trim()
            
            val priceIndex = remaining.lastIndexOf("RM")
            if (priceIndex == -1) return "$line\n"
            
            val qtyPart = remaining.substring(0, priceIndex).trim()
            val pricePart = remaining.substring(priceIndex).trim()
            
            return if (charsPerLine >= 48) {
                // 80mm: aligned on one line
                val leftPart = "$itemName x $qtyPart"
                padRight(leftPart, charsPerLine - pricePart.length) + pricePart + "\n"
            } else {
                // 58mm: stack on two lines
                "$itemName x $qtyPart\n" + padLeft(pricePart, charsPerLine) + "\n"
            }
        } catch (e: Exception) {
            return "$line\n"
        }
    }

    private fun formatTotalLineForSdk(line: String, charsPerLine: Int): String {
        try {
            val colonIndex = line.indexOf(':')
            if (colonIndex == -1) return "$line\n"
            
            val label = line.substring(0, colonIndex + 1).trim()
            val value = line.substring(colonIndex + 1).trim()
            
            return padRight(label, charsPerLine - value.length) + value + "\n"
        } catch (e: Exception) {
            return "$line\n"
        }
    }


    private fun isPrinterDevice(device: UsbDevice): Boolean {
        // Check common printer vendor/product IDs or interface classes
        return device.deviceClass == 7 || // Printer class
               device.interfaceCount > 0 && device.getInterface(0).interfaceClass == 7
    }

    private fun getDeviceName(device: UsbDevice): String {
        val manufacturer = device.manufacturerName ?: "Unknown"
        val product = device.productName ?: "USB Printer"
        return "$manufacturer $product"
    }

    private fun isBluetoothPrinter(device: BluetoothDevice): Boolean {
        val name = device.name?.lowercase() ?: ""
        return name.contains("printer") ||
               name.contains("receipt") ||
               name.contains("thermal") ||
               name.contains("pos")
    }

    // USB matching helpers
    private fun matchesUsbDevice(device: UsbDevice, identifier: String): Boolean {
        val id = identifier.trim()
        // Support VID:PID (hex or decimal), with optional VID/PID or 0x prefixes
        if (id.contains(":")) {
            val parts = id.split(":")
            if (parts.size >= 2) {
                val vidCandidates = parseUsbIdCandidates(parts[0])
                val pidCandidates = parseUsbIdCandidates(parts[1])
                return vidCandidates.contains(device.vendorId) && pidCandidates.contains(device.productId)
            }
            return false
        }

        // Otherwise, treat as Android UsbDevice.deviceId (decimal string)
        return try {
            val dec = id.toInt()
            device.deviceId == dec
        } catch (_: Exception) {
            false
        }
    }

    private fun parseUsbIdCandidates(raw: String): Set<Int> {
        val set = mutableSetOf<Int>()
        var token = raw.trim()
        if (token.isEmpty()) return emptySet()

        // Normalize: remove common prefixes and non-hex characters for a hex candidate
        val cleanedHex = token.uppercase(java.util.Locale.ROOT)
            .replace("VID", "")
            .replace("PID", "")
            .replace("0X", "")
            .replace(Regex("[^0-9A-F]"), "")

        if (cleanedHex.isNotEmpty()) {
            // If contains A-F letters, it's clearly hex
            val hasHexLetters = cleanedHex.any { it in 'A'..'F' }
            if (hasHexLetters) {
                parseIntSafe(cleanedHex, 16)?.let { set.add(it) }
            } else {
                // Could be either decimal or hex; try both
                parseIntSafe(cleanedHex, 10)?.let { set.add(it) }
                parseIntSafe(cleanedHex, 16)?.let { set.add(it) }
            }
        }

        // Also try raw decimal as-is if it was not purely hex-cleaned
        token = raw.trim()
        if (token.matches(Regex("^\\d+$"))) {
            parseIntSafe(token, 10)?.let { set.add(it) }
        }

        return set
    }

    private fun parseIntSafe(value: String, radix: Int): Int? {
        return try { Integer.parseInt(value, radix) } catch (_: Exception) { null }
    }

    // ESC/POS formatting helpers
    private fun centerAlign(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(1) // Center
    }

    private fun leftAlign(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(0) // Left
    }

    private fun centerAlignBold(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(1) // Center
        output.write(0x1B)
        output.write(0x45)
        output.write(1) // Bold on
    }

    private fun resetFormatting(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x45)
        output.write(0) // Bold off
        output.write(0x1D)
        output.write(0x21)
        output.write(0) // Normal size
        output.write(0x1B)
        output.write(0x61)
        output.write(0) // Left align
    }

    private fun repeatChar(char: Char, count: Int): String {
        return char.toString().repeat(count)
    }

    private fun padRight(text: String, width: Int): String {
        return if (text.length >= width) text.substring(0, width)
        else text + " ".repeat(width - text.length)
    }

    private fun padLeft(text: String, width: Int): String {
        return if (text.length >= width) text.substring(0, width)
        else " ".repeat(width - text.length) + text
    }

    private fun formatReceiptContent(output: java.io.ByteArrayOutputStream, content: String, charsPerLine: Int) {
        // Parse receipt content and format nicely
        val lines = content.split("\n")
        
        for (line in lines) {
            if (line.trim().isEmpty()) {
                output.write('\n'.code)
                continue
            }
            
            // Check if it's an item line (contains "x " pattern)
            if (line.contains(" x ")) {
                formatItemLine(output, line, charsPerLine)
            }
            // Check if it's a total/subtotal line (contains currency symbol)
            else if (line.contains("RM") || line.contains("Subtotal:") || line.contains("Tax") || 
                     line.contains("Service") || line.contains("Total:") || 
                     line.contains("Payment:") || line.contains("Paid:") || line.contains("Change:")) {
                formatTotalLine(output, line, charsPerLine)
            }
            else {
                // Regular line - just print as is
                output.write(line.toByteArray())
                output.write('\n'.code)
            }
        }
    }

    private fun formatItemLine(output: java.io.ByteArrayOutputStream, line: String, charsPerLine: Int) {
        // Parse: "Item Name x Qty RM Price"
        // Example: "Nasi Lemak x 2 RM 12.00"
        
        try {
            val parts = line.split(" x ")
            if (parts.size < 2) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val itemName = parts[0].trim()
            val remaining = parts[1].trim()
            
            // Find the price (last RM occurrence)
            val priceIndex = remaining.lastIndexOf("RM")
            if (priceIndex == -1) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val qtyPart = remaining.substring(0, priceIndex).trim()
            val pricePart = remaining.substring(priceIndex).trim()
            
            // Format based on paper width
            if (charsPerLine >= 48) {
                // 80mm: "Item Name x Qty         RM 12.00"
                val leftPart = "$itemName x $qtyPart"
                val formatted = padRight(leftPart, charsPerLine - pricePart.length) + pricePart
                output.write(formatted.toByteArray())
            } else {
                // 58mm: Stack on two lines
                output.write("$itemName x $qtyPart\n".toByteArray())
                output.write(padLeft(pricePart, charsPerLine).toByteArray())
            }
            output.write('\n'.code)
        } catch (e: Exception) {
            // Fallback: just print the line as is
            output.write(line.toByteArray())
            output.write('\n'.code)
        }
    }

    private fun formatTotalLine(output: java.io.ByteArrayOutputStream, line: String, charsPerLine: Int) {
        // Parse lines like "Subtotal: RM 24.00"
        try {
            val colonIndex = line.indexOf(':')
            if (colonIndex == -1) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val label = line.substring(0, colonIndex + 1).trim()
            val value = line.substring(colonIndex + 1).trim()
            
            // Right-align value
            val formatted = padRight(label, charsPerLine - value.length) + value
            output.write(formatted.toByteArray())
            output.write('\n'.code)
        } catch (e: Exception) {
            output.write(line.toByteArray())
            output.write('\n'.code)
        }
    }
}
