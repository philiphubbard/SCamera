SCamera: IOS Camera Handling in Swift
=====================================

By Philip M. Hubbard, 2017

Overview
--------

The SCamera framework provides Swift code to simplify the set up and use of the cameras from an iOS device.  Currently, it focuses on streaming frames from a video camera, and it supports changing between the front and back cameras and changing the camera orientation.  The [FacetiousIOS](http://github.com/philiphubbard/FacetiousIOS) app uses SCamera for the first step in capturing a face to be rendered with a warping shader.

Implementation
--------------

SCamera's `Video` class manages a session with the video camera of the device.
Its initializer takes a delegate, an instance of a class conforming to the `VideoDelegate` protocol.  The delegate's `captureVideo` and `droppedFrame` methods are called each time the camera generates (or discards) a new frame.  These methods get a `CMSampleBuffer` as an argument.  The `Video` class' `cgImage` type method is a convenient way for the delegate to create a `CGImage` from the `CMSampleBuffer`.

The `Video` class `start` method starts the stream of frames from the camera, and the `stop` method stops it.  Both methods are asynchronous, using a dispatch queue.  At any time (including after the stream has started) the `position` property can be used to get or set whether the front or back camera is active.  Likewise, the `orientation` property will get or set whether the camera is in landscape or portrait mode.  The processing associated with setting these properties is also asynchronous.

Testing
-------

The XCTest framework provides no way to simulate device cameras, so there are no tests for SCamera.  Future work could involve tests that would run only on a device, but these test would have to be somewhat imprecise as they could not control what the camera was pointed at and thus what would be in the frames being streamed.

Building
--------

SCamera is a framework to facilitate reuse.  The simplest way to use it as part of an app is to add its project file to an Xcode workspace that includes the app project.  Some of the steps in getting a custom framework to work with an app on a device are subtle, but the following steps work:

1. Close the SCamera project if it is open in Xcode.
2. Open the workspace.
3. In the Project Navigator panel on the left side of Xcode, right-click and choose "Add Files to <workspace name>..."
4. In the dialog, from the "SCamera" folder choose "SCamera.xcodeproj" and press "Add".
5. Select the app project in the Project Navigator, and in the "General" tab’s "Linked Frameworks and Libraries", press the "+" button.
6. In the dialog, from the "Workspace" folder choose "SCamera.framework" and press "Add".
7. In the "Build Phase" tab, press the "+" button (top left) and choose "New Copy Files Phase."  This phase will install the framework when the app is installed on a device.
8. In the "Copy Files" area, change the "Destination" to "Frameworks".
9. Drag into this "Copy Files" area the "SCamera.framework" file from the "Products" folder for SCamera in the Project Navigator.  Note that it is important to *drag* the framework from the "Products" folder: the alternative---pressing the "+" button in the "Copy Files" area and choosing any of the "SCamera.framework" items listed---will appear to work but will fail at run time.
10. In the dialog that appears after dragging, use the default settings (i.e., only "Create folder references" is checked) and press "Finish".

SCamera depends on the AVFoundation framework.  The specific version of Xcode used to develop SCamera was 8.3.
