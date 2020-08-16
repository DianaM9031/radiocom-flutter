import 'package:cuacfm/domain/repository/radiocom_repository_contract.dart';
import 'package:cuacfm/injector/dependency_injector.dart';
import 'package:cuacfm/models/radiostation.dart';
import 'package:cuacfm/ui/player/current_player.dart';
import 'package:cuacfm/ui/player/current_timer.dart';
import 'package:cuacfm/ui/podcast/controls/podcast_controls.dart';
import 'package:cuacfm/ui/podcast/controls/podcast_controls_presenter.dart';
import 'package:cuacfm/utils/connection_contract.dart';
import 'package:cuacfm/utils/neumorfism.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injector/injector.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../instrument/data/repository_mock.dart';
import '../../../instrument/helper/helper-instrument.dart';
import '../../../instrument/model/episode_instrument.dart';
import '../../../instrument/model/radio_station_instrument.dart';

void main() {
  MockRadiocoRepository mockRepository = MockRadiocoRepository();
  MockConnection mockConnection = MockConnection();
  MockCurrentTimerContract mockCurrentTimerContract = MockCurrentTimerContract();
  MockPlayer mockPlayer = MockPlayer();

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    DependencyInjector().loadModules();
    mockTranslationsWithLocale();
    Injector.appInstance.registerDependency<CuacRepositoryContract>(
            (_) => mockRepository,
        override: true);
    Injector.appInstance.registerDependency<CurrentTimerContract>(
            (_) => mockCurrentTimerContract,
        override: true);
    Injector.appInstance.registerDependency<ConnectionContract>(
            (_) => mockConnection,
        override: true);
    Injector.appInstance.registerDependency<CurrentPlayerContract>(
            (_) => mockPlayer,
        override: true);
    Injector.appInstance.registerDependency<RadioStation>(
            (_) => RadioStationInstrument.givenARadioStation(),
        override: true);
  });

  setUp(() async {
    mockPlayer = MockPlayer();
  });

  tearDown(() async {
    Injector.appInstance.removeByKey<PodcastControlsView>();
  });

  testWidgets('that in podcast controls can show info while playing live audio', (WidgetTester tester) async{
    when(mockRepository.getLiveBroadcast())
        .thenAnswer((_) => MockRadiocoRepository.now());
    when(mockConnection.isConnectionAvailable())
        .thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPlaying()).thenReturn(true);
    when(mockPlayer.stop()).thenReturn(true);
    when(mockPlayer.play()).thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPodcast).thenReturn(false);
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockCurrentTimerContract.currentTime).thenReturn(0);

    await tester.pumpWidget(startWidget(PodcastControls(episode: EpisodeInstrument.givenAnEpisode())));

    expect(
        find.byKey(Key("podcast_controls_container"),skipOffstage: true),
        findsOneWidget);
  });

  testWidgets('that in podcast controls can show info while playing podcast audio', (WidgetTester tester) async{
    when(mockRepository.getLiveBroadcast())
        .thenAnswer((_) => MockRadiocoRepository.now());
    when(mockConnection.isConnectionAvailable())
        .thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPlaying()).thenReturn(true);
    when(mockPlayer.stop()).thenReturn(true);
    when(mockPlayer.play()).thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPodcast).thenReturn(true);
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockPlayer.duration).thenReturn(Duration(seconds: 220));
    when(mockPlayer.position).thenReturn(Duration(seconds: 110));
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockCurrentTimerContract.currentTime).thenReturn(0);

    await tester.pumpWidget(startWidget(PodcastControls(episode: EpisodeInstrument.givenAnEpisode())));

    expect(
        find.byKey(Key("podcast_controls_container"),skipOffstage: true),
        findsOneWidget);
  });

  testWidgets('that in podcast controls can put a timer properly', (WidgetTester tester) async{
    when(mockRepository.getLiveBroadcast())
        .thenAnswer((_) => MockRadiocoRepository.now());
    when(mockConnection.isConnectionAvailable())
        .thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPlaying()).thenReturn(true);
    when(mockPlayer.stop()).thenReturn(true);
    when(mockPlayer.play()).thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPodcast).thenReturn(true);
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockPlayer.duration).thenReturn(Duration(seconds: 220));
    when(mockPlayer.position).thenReturn(Duration(seconds: 110));
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockCurrentTimerContract.currentTime).thenReturn(110);

    await tester.pumpWidget(startWidget(PodcastControls(episode: EpisodeInstrument.givenAnEpisode())));
    final gesture = await tester.startGesture(Offset(0, 600));
    await gesture.moveBy(Offset(0, -600));
    await tester.pump();
    await tester.tap(find.byKey(Key("timer_chip_15_min")));
    await tester.pump(Duration(milliseconds: 300));

    expect(
        find.byType(NeumorphicView, skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('that in podcast controls can handle error on connection while playing', (WidgetTester tester) async{
    when(mockRepository.getLiveBroadcast())
        .thenAnswer((_) => MockRadiocoRepository.now());
    when(mockConnection.isConnectionAvailable())
        .thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPlaying()).thenReturn(false);
    when(mockPlayer.stop()).thenReturn(true);
    when(mockPlayer.play()).thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPodcast).thenReturn(false);
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockCurrentTimerContract.currentTime).thenReturn(0);
    when(mockPlayer.onConnection).thenReturn((isError){
      tester.allStates.forEach((state){
        if( state is PodcastControlsState){
          state.onConnectionError();
        }
      });
    });

    await tester.pumpWidget(startWidget(PodcastControls(episode: EpisodeInstrument.givenAnEpisode())));
    mockPlayer.onConnection(true);
    await tester.pumpAndSettle();

    expect(
        find.byKey(Key("connection_snackbar"),skipOffstage: true),
        findsOneWidget);
  });

  testWidgets('that in podcast controls can put playback rate for faster', (WidgetTester tester) async{
    when(mockRepository.getLiveBroadcast())
        .thenAnswer((_) => MockRadiocoRepository.now());
    when(mockConnection.isConnectionAvailable())
        .thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPlaying()).thenReturn(true);
    when(mockPlayer.stop()).thenReturn(true);
    when(mockPlayer.play()).thenAnswer((_) => Future.value(true));
    when(mockPlayer.isPodcast).thenReturn(true);
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockPlayer.duration).thenReturn(Duration(seconds: 220));
    when(mockPlayer.position).thenReturn(Duration(seconds: 110));
    when(mockPlayer.currentSong).thenReturn("mocklive");
    when(mockPlayer.playbackRate).thenReturn(1.5);
    when(mockCurrentTimerContract.currentTime).thenReturn(110);

    await tester.pumpWidget(startWidget(PodcastControls(episode: EpisodeInstrument.givenAnEpisode())));
    final gesture = await tester.startGesture(Offset(0, 600));
    await gesture.moveBy(Offset(0, -600));
    await tester.pump();
    await tester.tap(find.byKey(Key("faster_chip_3_speed")));
    await tester.pump(Duration(milliseconds: 300));

    expect(
        find.byType(NeumorphicView, skipOffstage: false),
        findsOneWidget);
  });
}
