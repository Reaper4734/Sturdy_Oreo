import 'dart:async';
import '../models/micro_interview_model.dart';
import '../services/file_picker_service.dart';

class MockInterviewRepository {
  static final MockInterviewRepository _instance = MockInterviewRepository._internal();
  factory MockInterviewRepository() => _instance;
  MockInterviewRepository._internal();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'm1',
      sender: 'AI',
      text: "Hey there! Welcome to Oreo. Before we start building a massive study plan or throwing tutorials at you, I just want to get to know you a bit. What's your current situation? Are we aiming for a specific placement, building a startup, or just trying to survive the semester?",
      options: [
        "honestly just surviving 3rd year right now lol. i am at a college in pune and placement tension is starting. tried MERN courses on youtube but gave up after 2 weeks.",
        "Building a real-time startup MVP with WebSockets and React",
        "Preparing for Tier-1 Product Company System Design Interviews",
      ],
    ),
  ];

  int _step = 1;

  Future<List<ChatMessage>> getInitialMessages() async {
    return List.unmodifiable(_messages);
  }

  Future<ChatMessage> sendUserResponse(String text, {List<AttachedFileModel>? files}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _step++;

    if (_step == 2) {
      final reply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: "Ah, the classic 'tutorial hell.' Copy-pasting code for 4 hours a day will drain anyone's soul. If you hated the copy-pasting, how do you usually prefer to learn things? Like, if you had to learn how to play a complex new video game, do you read the manual, watch a streamer, or just press buttons until you figure it out?",
        options: [
          "definitely just press buttons. i skip tutorials in games. i need to break things to understand how they work. long theory lectures turn my brain off.",
          "I prefer visual diagrams and structural flowcharts first",
          "Show me working code snippets with step-by-step execution",
        ],
      );
      _messages.add(reply);
      return reply;
    } else if (_step == 3) {
      final reply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: "Got it. You're a 'break it to build it' kind of learner. Imagine you're running Swiggy or Zomato on the night of an India-Pak cricket match. The app crashes because 5 lakh people order at once. What part of fixing this sounds most interesting to you?\n\nA) Designing a lightweight UI so it loads faster\nB) Rerouting server traffic and writing queue scripts so backend doesn't melt\nC) Looking at past data to predict order spikes",
        options: [
          "B for sure. C sounds like way too much maths and A is just making things look pretty. B sounds like actual problem solving under pressure.",
          "A) Lightweight UI and client-side optimization",
          "C) Predictive Data Science and Analytics",
        ],
      );
      _messages.add(reply);
      return reply;
    } else if (_step == 4) {
      final reply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: "Nice choice. Rerouting that traffic is pure Backend Engineering and Cloud Architecture.\n\nBut here is the catch: Backend bugs can be completely invisible. Let's say you get a '500 Internal Server Error' with NO logs. You stare at red text for 2 hours. What goes through your head, and what do you actually do next?",
        options: [
          "after 2 hours I’d probably question why I took engineering 💀. shut my laptop, get chai with flatmates, ask a senior to look at it because I’m blind to my mistakes by then.",
          "Keep digging through stack traces systematically",
          "Use automated debugging tools and break down module logic",
        ],
      );
      _messages.add(reply);
      return reply;
    } else {
      final reply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'AI',
        text: "Honestly, walking away for chai is the most authentic developer debugging strategy ever invented. 😂\n\nHere is what I’m seeing: You're a hands-on, systems-level thinker who hates passive lectures. You want to build backend logic, but you need a 'safety net' senior figure so you never get stuck in a 2-hour loop.\n\nWe are officially skipping standard 40-hour video courses. I built you a Python & FastAPI Backend Track with interactive sandboxes! Ready to view your Subject Mind Map?",
        options: [
          "yes please. let's go ➔",
        ],
      );
      _messages.add(reply);
      return reply;
    }
  }
}
