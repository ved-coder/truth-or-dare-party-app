import 'dart:math';
import '../models/prompt_model.dart';

class PromptRepository {
  static final Random _rng = Random();

  static final List<PromptItem> _allPrompts = [
    // --- TRUTHS: MILD ---
    const PromptItem(
      id: 't_m_1',
      text: 'What is the most embarrassing thing in your search history?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Confessions',
    ),
    const PromptItem(
      id: 't_m_2',
      text: 'What is your biggest irrational fear that makes people laugh?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Secrets',
    ),
    const PromptItem(
      id: 't_m_3',
      text: 'Have you ever rehearsed a conversation in front of a mirror? What was it about?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Awkward',
    ),
    const PromptItem(
      id: 't_m_4',
      text: 'What is the worst haircut or fashion choice you ever had in your life?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Blunders',
    ),
    const PromptItem(
      id: 't_m_5',
      text: 'If you had to swap lives with one person in this room for 24 hours, who would it be?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Friends',
    ),
    const PromptItem(
      id: 't_m_6',
      text: 'What is the strangest food combination you secretly enjoy?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Weird Habits',
    ),
    const PromptItem(
      id: 't_m_7',
      text: 'What is a lie you told to get out of hanging out with someone?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Confessions',
    ),
    const PromptItem(
      id: 't_m_8',
      text: 'Who in this room would survive the longest in a zombie apocalypse?',
      type: PromptType.truth,
      intensity: IntensityLevel.mild,
      category: 'Survival',
    ),

    // --- TRUTHS: SPICY ---
    const PromptItem(
      id: 't_s_1',
      text: 'What is the biggest romantic blunder or awkward first date you have ever had?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Romance',
    ),
    const PromptItem(
      id: 't_s_2',
      text: 'Who in this room gives off the biggest "secret villain" energy?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Vibes',
    ),
    const PromptItem(
      id: 't_s_3',
      text: 'What is something you pretend to dislike just because it is popular, but secretly enjoy?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Guilty Pleasure',
    ),
    const PromptItem(
      id: 't_s_4',
      text: 'Have you ever snooped through someone’s phone or diary? What did you find?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Snooping',
    ),
    const PromptItem(
      id: 't_s_5',
      text: 'What is the most ridiculous rumor you heard about yourself that wasn’t true?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Drama',
    ),
    const PromptItem(
      id: 't_s_6',
      text: 'If you were forced to delete all social media except one, which one stays?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Social',
    ),
    const PromptItem(
      id: 't_s_7',
      text: 'Who was your most embarrassing celebrity or cartoon crush growing up?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Crushes',
    ),
    const PromptItem(
      id: 't_s_8',
      text: 'What is something you did in school that you never got caught for?',
      type: PromptType.truth,
      intensity: IntensityLevel.spicy,
      category: 'Rebel',
    ),

    // --- TRUTHS: EXTREME ---
    const PromptItem(
      id: 't_e_1',
      text: 'Show your current screen time and your most used app right now to the group!',
      type: PromptType.truth,
      intensity: IntensityLevel.extreme,
      category: 'Exposed',
    ),
    const PromptItem(
      id: 't_e_2',
      text: 'Read the last 3 text messages you received out loud with zero context.',
      type: PromptType.truth,
      intensity: IntensityLevel.extreme,
      category: 'Exposed',
    ),
    const PromptItem(
      id: 't_e_3',
      text: 'If you had to cut ties with one friend in your contact list right now, who would it be?',
      type: PromptType.truth,
      intensity: IntensityLevel.extreme,
      category: 'Danger Zone',
    ),
    const PromptItem(
      id: 't_e_4',
      text: 'What is the pettiest reason you ever refused to talk to someone or stopped texting them?',
      type: PromptType.truth,
      intensity: IntensityLevel.extreme,
      category: 'Petty',
    ),
    const PromptItem(
      id: 't_e_5',
      text: 'What is the deepest secret you have kept from your parents?',
      type: PromptType.truth,
      intensity: IntensityLevel.extreme,
      category: 'Secrets',
    ),

    // --- DARES: MILD ---
    const PromptItem(
      id: 'd_m_1',
      text: 'Speak in an exaggerated British royal accent until your next turn!',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Acting',
    ),
    const PromptItem(
      id: 'd_m_2',
      text: 'Do your best impression of another player in this room until they guess who it is.',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Impression',
    ),
    const PromptItem(
      id: 'd_m_3',
      text: 'Do 15 rapid jumping jacks while singing your favorite cartoon theme song.',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Physical',
    ),
    const PromptItem(
      id: 'd_m_4',
      text: 'Let the person to your left redo your hair into any funny style for the next 2 rounds.',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Styling',
    ),
    const PromptItem(
      id: 'd_m_5',
      text: 'Attempt to balance a spoon on your nose for 30 uninterrupted seconds!',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Skill',
    ),
    const PromptItem(
      id: 'd_m_6',
      text: 'Talk like an auctioneer for 45 seconds about an ordinary object near you.',
      type: PromptType.dare,
      intensity: IntensityLevel.mild,
      category: 'Voice',
    ),

    // --- DARES: SPICY ---
    const PromptItem(
      id: 'd_s_1',
      text: 'Post a funny selfie chosen by the group on your Instagram/Snapchat story for 10 minutes!',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Social Media',
    ),
    const PromptItem(
      id: 'd_s_2',
      text: 'Send a voice note to the 3rd person in your WhatsApp/iMessage saying "The prophecy has come true."',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Prank',
    ),
    const PromptItem(
      id: 'd_s_3',
      text: 'Let another player tweet or status-post a sentence of their choice from your phone.',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Takeover',
    ),
    const PromptItem(
      id: 'd_s_4',
      text: 'Put an ice cube in your hand and hold it until it completely melts without letting go!',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Endurance',
    ),
    const PromptItem(
      id: 'd_s_5',
      text: 'Call a random pizza place or bakery and ask if they have gluten-free water.',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Call Prank',
    ),
    const PromptItem(
      id: 'd_s_6',
      text: 'Perform an intense dramatic monologue about how much you love potatoes.',
      type: PromptType.dare,
      intensity: IntensityLevel.spicy,
      category: 'Performance',
    ),

    // --- DARES: EXTREME ---
    const PromptItem(
      id: 'd_e_1',
      text: 'Eat a spoonful of hot sauce or raw mustard without making any reaction or face for 1 full minute!',
      type: PromptType.dare,
      intensity: IntensityLevel.extreme,
      category: 'Taste Test',
    ),
    const PromptItem(
      id: 'd_e_2',
      text: 'Let the players browse through your camera roll favorites for 30 seconds!',
      type: PromptType.dare,
      intensity: IntensityLevel.extreme,
      category: 'Exposed',
    ),
    const PromptItem(
      id: 'd_e_3',
      text: 'Do a 60-second plank while reciting the alphabet backwards!',
      type: PromptType.dare,
      intensity: IntensityLevel.extreme,
      category: 'Challenge',
    ),
    const PromptItem(
      id: 'd_e_4',
      text: 'Call your best friend or sibling and pretend you just won the lottery and need an alibi.',
      type: PromptType.dare,
      intensity: IntensityLevel.extreme,
      category: 'Prank Call',
    ),
  ];

  static PromptItem getRandomPrompt({
    required PromptType type,
    IntensityLevel intensity = IntensityLevel.spicy,
    List<PromptItem> customPrompts = const [],
  }) {
    final combined = [
      ..._allPrompts.where((p) => p.type == type && (p.intensity == intensity || intensity == IntensityLevel.extreme)),
      ...customPrompts.where((p) => p.type == type),
    ];

    if (combined.isEmpty) {
      // fallback
      final fallbackPool = _allPrompts.where((p) => p.type == type).toList();
      return fallbackPool[_rng.nextInt(fallbackPool.length)];
    }

    return combined[_rng.nextInt(combined.length)];
  }

  static List<PromptItem> get allBuiltInPrompts => List.unmodifiable(_allPrompts);
}
