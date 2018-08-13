package com.example.otherside;

import android.os.Bundle;
import com.mapbox.mapboxsdk.Mapbox;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    Mapbox.getInstance(this, BuildConfig.MAPBOX_ACCESS_TOKEN);
  }
}
