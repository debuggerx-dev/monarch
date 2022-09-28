#pragma once

#include <string>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_result_functions.h>

#include "window_manager.h"
#include "monarch_state.h"
#include "channels_utils.h"

class HeadlessWindowManager;

const std::string controllerChannelName = "monarch.controller";
const std::string previewChannelName = "monarch.preview";

class Channels
{
public:
	Channels(
		flutter::BinaryMessenger* controllerMessenger,
		flutter::BinaryMessenger* previewMessenger,
		HeadlessWindowManager* windowManager_);
	~Channels();

	void setUpCallForwarding();
	void sendWillClosePreview();
	void unregisterMethodCallHandlers();
	void restartPreviewChannel(flutter::BinaryMessenger* previewMessenger);

	std::unique_ptr<flutter::MethodChannel<EncodableValue>> controllerChannel;
	std::unique_ptr<flutter::MethodChannel<EncodableValue>> previewChannel;
	HeadlessWindowManager* windowManager;

private:
	void _forwardMethodCall(
		const flutter::MethodCall<EncodableValue>& call,
		std::unique_ptr<flutter::MethodResult<EncodableValue>>& callback ,
		std::unique_ptr<flutter::MethodChannel<EncodableValue>>& forwardChannel);
};

namespace MonarchMethods
{
	const std::string setActiveDevice = "monarch.setActiveDevice";
	const std::string setStoryScale = "monarch.setStoryScale";
	const std::string setDockSide = "monarch.setDockSide";
	const std::string getState = "monarch.getState";
	const std::string screenChanged = "monarch.screenChanged";
	const std::string restartPreview = "monarch.restartPreview";
	const std::string willClosePreview = "monarch.willClosePreview";
};

