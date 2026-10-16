import Foundation

// MARK: - ADHDDailyTip

struct ADHDDailyTip: Identifiable, Codable, Hashable {
    let id: Int
    let category: String
    let quote: String
    let actionableTip: String

    /// Computes today's tip based on the day of the year so it changes every calendar day.
    static func tip(for date: Date = Date()) -> ADHDDailyTip {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = abs(dayOfYear - 1) % allTips.count
        return allTips[index]
    }

    static func tip(at index: Int) -> ADHDDailyTip {
        let safeIndex = abs(index) % allTips.count
        return allTips[safeIndex]
    }

    static let allTips: [ADHDDailyTip] = [
        ADHDDailyTip(
            id: 1,
            category: "Momentum",
            quote: "Action precedes motivation, not the other way around.",
            actionableTip: "Give yourself permission to do just 2 minutes of a task. Breaking the friction of starting is 80% of the battle."
        ),
        ADHDDailyTip(
            id: 2,
            category: "Calm",
            quote: "Focus on the exhale to reset an overstimulated nervous system.",
            actionableTip: "A 4-second inhale followed by a slow 6-second exhale signals your brain to lower cortisol and ease tension."
        ),
        ADHDDailyTip(
            id: 3,
            category: "Self-Compassion",
            quote: "You are not lazy or broken; your brain simply needs dopamine to initiate action.",
            actionableTip: "Forgive yesterday's undone list. Guilt and shame drain the exact dopamine you need to function today."
        ),
        ADHDDailyTip(
            id: 4,
            category: "Working Memory",
            quote: "Your brain is for generating ideas, not storing them.",
            actionableTip: "Braindump racing thoughts onto paper or voice memos to clear your working memory RAM."
        ),
        ADHDDailyTip(
            id: 5,
            category: "Executive Function",
            quote: "If a task feels paralyzing, make the first step ridiculously small.",
            actionableTip: "Don't 'clean the room'—just pick up one sock. Tiny micro-steps bypass the brain's overwhelm trigger."
        ),
        ADHDDailyTip(
            id: 6,
            category: "Dopamine",
            quote: "Work with your neurochemistry instead of fighting it.",
            actionableTip: "Pair tedious chores with a favorite podcast, upbeat playlist, or enjoyable beverage for an instant dopamine boost."
        ),
        ADHDDailyTip(
            id: 7,
            category: "Focus",
            quote: "Body doubling can turn executive paralysis into flow.",
            actionableTip: "Working alongside someone else or playing gentle cafe background sounds helps anchor ADHD attention."
        ),
        ADHDDailyTip(
            id: 8,
            category: "Energy",
            quote: "Rest is productive, not lazy.",
            actionableTip: "An ADHD brain runs at 200 mph. Scheduled micro-rests before burnout prevent prolonged fatigue."
        ),
        ADHDDailyTip(
            id: 9,
            category: "Perfectionism",
            quote: "Done and messy beats perfect in your imagination every single time.",
            actionableTip: "Lower the bar to 'good enough'. Completion releases dopamine; perfectionism leads to paralysis."
        ),
        ADHDDailyTip(
            id: 10,
            category: "Time Blindness",
            quote: "Make time visual so your brain can perceive it.",
            actionableTip: "Use visual progress bars or gentle sound timers instead of standard clocks to stay grounded in the now."
        ),
        ADHDDailyTip(
            id: 11,
            category: "Transitions",
            quote: "Gear shifts take real energy for an ADHD mind.",
            actionableTip: "Give yourself a 5-minute buffer between tasks rather than forcing an abrupt, jarring switch."
        ),
        ADHDDailyTip(
            id: 12,
            category: "Sensory Reset",
            quote: "Sensory overload often disguises itself as irritability or anxiety.",
            actionableTip: "Dim the screen, put on noise-cancelling headphones, and pause for two minutes of deep quiet."
        ),
        ADHDDailyTip(
            id: 13,
            category: "Novelty",
            quote: "Novelty is essential fuel for neurodivergent focus.",
            actionableTip: "When a routine gets stale, tweak your environment: change desks, switch pens, or play a fresh ambient track."
        ),
        ADHDDailyTip(
            id: 14,
            category: "Movement",
            quote: "Movement helps the ADHD brain think and process.",
            actionableTip: "Quiet fidgets, pacing during calls, or stretching between tasks actually enhance focus and retention."
        ),
        ADHDDailyTip(
            id: 15,
            category: "Impulse Control",
            quote: "Give exciting ideas a 24-hour waiting room.",
            actionableTip: "Before committing to a new project or big purchase, jot it down and sleep on it to filter impulsivity."
        ),
        ADHDDailyTip(
            id: 16,
            category: "Self-Worth",
            quote: "Your worth as a human is not measured by your daily productivity.",
            actionableTip: "You are allowed to have low-capacity days. Be kind to yourself today."
        ),
        ADHDDailyTip(
            id: 17,
            category: "Object Permanence",
            quote: "Out of sight is out of mind for ADHD brains.",
            actionableTip: "Keep your daily essentials and top priority visibly in front of you on open trays or sticky notes."
        ),
        ADHDDailyTip(
            id: 18,
            category: "Decision Fatigue",
            quote: "Save your decision bandwidth for what truly matters.",
            actionableTip: "Automate repetitive daily choices like what to wear or have for breakfast to prevent early cognitive drain."
        ),
        ADHDDailyTip(
            id: 19,
            category: "Hyperfocus",
            quote: "Hyperfocus is your superpower when steered with awareness.",
            actionableTip: "Set a recurring gentle chime before entering a flow state so you remember water, food, and posture checks."
        ),
        ADHDDailyTip(
            id: 20,
            category: "Micro-Wins",
            quote: "Every small victory counts toward rebuilding executive stamina.",
            actionableTip: "Sent one reply? Drank a glass of water? Acknowledge it! Your brain needs recognition to keep going."
        ),
        ADHDDailyTip(
            id: 21,
            category: "Environment",
            quote: "Organize for where you naturally drop things, not where they 'should' go.",
            actionableTip: "Place baskets and bins right at your natural dumping spots to make tidying effortless."
        ),
        ADHDDailyTip(
            id: 22,
            category: "Task Initiation",
            quote: "Use the 5-4-3-2-1 rule to leapfrog over hesitation.",
            actionableTip: "Count down backwards and move your body immediately before your mind constructs an obstacle."
        ),
        ADHDDailyTip(
            id: 23,
            category: "Mindset",
            quote: "ADHD is not a deficit of attention; it's a challenge of regulating attention.",
            actionableTip: "Celebrate your rapid creative connections and ability to dive deep into topics that matter."
        ),
        ADHDDailyTip(
            id: 24,
            category: "Emotional Regulation",
            quote: "Feelings are intense, but they are temporary weather in your mind.",
            actionableTip: "When feeling rejected or overwhelmed, step away from screens and place both feet flat on the floor."
        ),
        ADHDDailyTip(
            id: 25,
            category: "Hydration",
            quote: "Brain fog often starts with simple dehydration.",
            actionableTip: "Keep a water bottle with a straw within arm's reach; low-friction sips keep neurotransmitters firing."
        ),
        ADHDDailyTip(
            id: 26,
            category: "Pacing",
            quote: "You have a sports car engine with bicycle brakes—be patient while learning to steer.",
            actionableTip: "Don't judge yourself for needing different strategies than others. Your unique brain requires custom tools."
        ),
        ADHDDailyTip(
            id: 27,
            category: "Boundaries",
            quote: "Saying 'no' to one thing is saying 'yes' to your peace of mind.",
            actionableTip: "Protect your calendar by reserving unscheduled white space for spontaneous decompression."
        ),
        ADHDDailyTip(
            id: 28,
            category: "Creative Flow",
            quote: "Embrace non-linear progress—growth with ADHD is a spiral, not a straight ladder.",
            actionableTip: "Circling back to an old project or struggle isn't failure; you bring new wisdom every loop."
        ),
        ADHDDailyTip(
            id: 29,
            category: "Nighttime Calm",
            quote: "An active evening mind needs a gentle ramp-down, not a hard stop.",
            actionableTip: "Replace scrolling with warm tea, dim lighting, or sensory ambient sound 30 minutes before sleep."
        ),
        ADHDDailyTip(
            id: 30,
            category: "Self-Advocacy",
            quote: "Asking for clarity or extra time is a strength, not a weakness.",
            actionableTip: "Communicate your working style with confidence. Clear agreements prevent anxiety and missed steps."
        ),
        ADHDDailyTip(
            id: 31,
            category: "Grace",
            quote: "Today is a fresh canvas. Start again with curiosity, not criticism.",
            actionableTip: "One mindful breath can reset your entire trajectory for the afternoon."
        )
    ]
}
