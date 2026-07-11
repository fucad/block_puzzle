/// The ONLY place the quest content location is configured. Forks change
/// this one constant. The app's sole network destination (see PURPOSE.md:
/// no ads, no analytics, no other calls — ever).
const String questContentBaseUrl =
    'https://raw.githubusercontent.com/fucad/block_puzzle/main/content/quests';

/// Re-check the manifest at most this often.
const Duration questRefreshInterval = Duration(hours: 12);

/// Give up quickly; the app must feel identical offline.
const Duration questFetchTimeout = Duration(seconds: 5);
