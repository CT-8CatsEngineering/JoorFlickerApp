# JoorFlickerApp
Code Sample project

To run this simply select the target for the simulator, build and run. It will launch initially with an empty search field and tableview. Enter a topic hit enter and if you are connected to the interent the images will start loading. Tapping on one will open it in a full screen view, sized to best fit the screen.

If you close the app or terminate it in the simulator it will save the currently loaded results. NOTE: if you terminate the app from xcode it will not save the search results. The next time you launch it it will load the results that were stored from the previous search in the same position that it was in before. If you tap cancel it will clear the search results from both the UI and local storage.

If you are not connected to the internet and have loaded a search it will post an alert the first time it can't connect and reveal a button in the top right, if you click the button it will show the same alert. When you reconnect to the internet the button will disappear.
