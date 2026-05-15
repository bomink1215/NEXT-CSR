{{flutter_js}}
{{flutter_build_config}}

// 이미 Flutter가 실행 중이면 중복 실행 방지
if (!window._flutterAppStarted) {
  window._flutterAppStarted = true;
  
  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    },
  });
}