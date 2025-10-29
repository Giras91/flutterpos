#include "printer_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

void PrinterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.extrotarget.extropos/printer",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<PrinterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

PrinterPlugin::PrinterPlugin() {}

PrinterPlugin::~PrinterPlugin() {}

void PrinterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // For now, return success for all operations to allow the app to build
  if (method_call.method_name().compare("discoverPrinters") == 0) {
    flutter::EncodableList printers;
    // Return empty list for now
    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("printReceipt") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("printOrder") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("testPrint") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("checkPrinterStatus") == 0) {
    result->Success(flutter::EncodableValue("online"));
  } else {
    result->NotImplemented();
  }
}

void PrinterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  PrinterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}