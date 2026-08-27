
// ── Question ──────────────────────────────────────────────────────────────────
class Question {
  final String id;
  final String questionText;
  final List<String>? options;
  final String answerKey;
  final String explanation;
  final int marks;

  const Question({
    required this.id,
    required this.questionText,
    this.options,
    required this.answerKey,
    required this.explanation,
    required this.marks,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      answerKey: json['answerKey']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      marks: (json['marks'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionText': questionText,
    if (options != null) 'options': options,
    'answerKey': answerKey,
    'explanation': explanation,
    'marks': marks,
  };
}

// ── ExamSection ───────────────────────────────────────────────────────────────
class ExamSection {
  final String type; // 'MCQ', 'SHORT', 'LONG'
  final String? title;
  final String? instructions;
  final List<Question> questions;

  const ExamSection({
    required this.type,
    this.title,
    this.instructions,
    required this.questions,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    return ExamSection(
      type: json['type']?.toString() ?? 'MCQ',
      title: json['title']?.toString(),
      instructions: json['instructions']?.toString(),
      questions: rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (title != null) 'title': title,
    if (instructions != null) 'instructions': instructions,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  int get totalMarks => questions.fold(0, (sum, q) => sum + q.marks);
}

// ── GeneratedExam ─────────────────────────────────────────────────────────────
class GeneratedExam {
  final String title;
  final int totalMarks;
  final String? timeAllowed;
  final List<String>? instructions;
  final List<ExamSection> sections;

  const GeneratedExam({
    required this.title,
    required this.totalMarks,
    this.timeAllowed,
    this.instructions,
    required this.sections,
  });

  factory GeneratedExam.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List? ?? [];
    return GeneratedExam(
      title: json['title']?.toString() ?? 'Practice Exam',
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      timeAllowed: json['timeAllowed']?.toString(),
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'] as List)
          : null,
      sections: rawSections
          .map((s) => ExamSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'totalMarks': totalMarks,
    if (timeAllowed != null) 'timeAllowed': timeAllowed,
    if (instructions != null) 'instructions': instructions,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  static GeneratedExam get mockExam => GeneratedExam(
    title: 'Chapter 4: Cell Biology — Practice Exam',
    totalMarks: 40,
    timeAllowed: '60 minutes',
    instructions: const [
      'Attempt all questions.',
      'MCQ section: Choose the most appropriate answer.',
      'Short answers: Write in 2–3 sentences.',
      'Long answers: Write in detail with diagrams where applicable.',
    ],
    sections: [
      ExamSection(
        type: 'MCQ',
        title: 'Section A: Multiple Choice Questions',
        instructions: 'Each question carries 2 marks. Choose the best answer.',
        questions: [
          const Question(
            id: 'mcq_1',
            questionText:
                'Which organelle is responsible for ATP synthesis through oxidative phosphorylation?',
            options: [
              'A. Endoplasmic Reticulum',
              'B. Golgi Apparatus',
              'C. Mitochondria',
              'D. Lysosome',
            ],
            answerKey: 'C. Mitochondria',
            explanation:
                'Mitochondria are the powerhouses of the cell, producing ATP via the electron transport chain and oxidative phosphorylation in their inner membrane.',
            marks: 2,
          ),
          const Question(
            id: 'mcq_2',
            questionText:
                'The fluid mosaic model of the cell membrane was proposed by:',
            options: [
              'A. Watson and Crick',
              'B. Singer and Nicolson',
              'C. Schleiden and Schwann',
              'D. Hooke and Leeuwenhoek',
            ],
            answerKey: 'B. Singer and Nicolson',
            explanation:
                'Singer and Nicolson proposed the fluid mosaic model in 1972, describing the membrane as a fluid phospholipid bilayer with embedded proteins.',
            marks: 2,
          ),
          const Question(
            id: 'mcq_3',
            questionText:
                'Which process is responsible for the bulk transport of large molecules INTO the cell?',
            options: [
              'A. Exocytosis',
              'B. Osmosis',
              'C. Endocytosis',
              'D. Active transport',
            ],
            answerKey: 'C. Endocytosis',
            explanation:
                'Endocytosis is the process by which cells engulf large molecules or particles by folding the membrane around them to form a vesicle.',
            marks: 2,
          ),
          const Question(
            id: 'mcq_4',
            questionText: 'Ribosomes are composed of:',
            options: [
              'A. DNA and proteins',
              'B. rRNA and proteins',
              'C. mRNA and lipids',
              'D. tRNA and carbohydrates',
            ],
            answerKey: 'B. rRNA and proteins',
            explanation:
                'Ribosomes consist of ribosomal RNA (rRNA) and ribosomal proteins, assembled in two subunits (large and small) in the nucleolus.',
            marks: 2,
          ),
          const Question(
            id: 'mcq_5',
            questionText:
                'The nuclear envelope is continuous with which other organelle?',
            options: [
              'A. Golgi Apparatus',
              'B. Smooth ER',
              'C. Rough Endoplasmic Reticulum',
              'D. Vacuole',
            ],
            answerKey: 'C. Rough Endoplasmic Reticulum',
            explanation:
                'The outer membrane of the nuclear envelope is continuous with the rough endoplasmic reticulum, allowing direct transport of proteins.',
            marks: 2,
          ),
        ],
      ),
      ExamSection(
        type: 'SHORT',
        title: 'Section B: Short Answer Questions',
        instructions: 'Answer in 2–3 sentences. Each question carries 4 marks.',
        questions: [
          const Question(
            id: 'short_1',
            questionText:
                'Explain the role of the Golgi apparatus in protein processing and secretion.',
            options: null,
            answerKey:
                'The Golgi apparatus receives proteins from the rough ER, modifies them (e.g., glycosylation), sorts them, and packages them into vesicles for secretion or delivery to other organelles.',
            explanation:
                'Think of the Golgi as the cell\'s post office — it receives, modifies, packages, and dispatches proteins to their final destinations.',
            marks: 4,
          ),
          const Question(
            id: 'short_2',
            questionText:
                'Differentiate between prokaryotic and eukaryotic cells with respect to membrane-bound organelles.',
            options: null,
            answerKey:
                'Eukaryotic cells contain membrane-bound organelles such as the nucleus, mitochondria, and ER. Prokaryotic cells lack a true nucleus and membrane-bound organelles; their DNA floats freely in the cytoplasm.',
            explanation:
                'The "eu" in eukaryote means "true" nucleus. Prokaryotes evolved first and are structurally simpler — no membrane compartments.',
            marks: 4,
          ),
          const Question(
            id: 'short_3',
            questionText:
                'What is the significance of the semi-permeable nature of the plasma membrane?',
            options: null,
            answerKey:
                'The semi-permeable membrane allows selective passage of substances, maintaining homeostasis by controlling what enters and exits the cell. This is essential for regulating ion concentrations, nutrient uptake, and waste removal.',
            explanation:
                'Selective permeability is fundamental to cell survival — without it, toxic substances would enter freely and essential molecules would leak out.',
            marks: 4,
          ),
        ],
      ),
      ExamSection(
        type: 'LONG',
        title: 'Section C: Long Answer Questions',
        instructions:
            'Answer in detail. Diagrams are encouraged. Each question carries 6 marks.',
        questions: [
          const Question(
            id: 'long_1',
            questionText:
                'Describe the structure and function of mitochondria. Include the role of the inner membrane in ATP synthesis.',
            options: null,
            answerKey:
                'Mitochondria have a double membrane: the outer membrane is smooth and permeable, while the inner membrane is highly folded into cristae. The cristae dramatically increase surface area for the electron transport chain. The matrix (inner space) contains enzymes for the Krebs cycle. ATP synthase embedded in the cristae uses the proton gradient (generated by the ETC) to synthesize ATP via chemiosmosis. This process — oxidative phosphorylation — produces approximately 32–34 ATP per glucose molecule.',
            explanation:
                'Key marks: double membrane structure (1), cristae and their function (1), matrix and Krebs cycle location (1), ETC and proton gradient (1), ATP synthase / chemiosmosis (1), ATP yield (1).',
            marks: 6,
          ),
          const Question(
            id: 'long_2',
            questionText:
                'With the aid of a diagram, explain the fluid mosaic model of the cell membrane and describe three mechanisms of membrane transport.',
            options: null,
            answerKey:
                'The fluid mosaic model (Singer & Nicolson, 1972) describes the membrane as a phospholipid bilayer in which proteins are embedded and can move laterally. Key components: phospholipids (hydrophilic heads outward, hydrophobic tails inward), integral proteins (spanning the bilayer), peripheral proteins (surface-attached), cholesterol (fluidity regulation), and glycoproteins (cell recognition). Transport mechanisms: (1) Simple diffusion — non-polar molecules move down concentration gradient, no energy required. (2) Facilitated diffusion — polar molecules use channel or carrier proteins, no energy required. (3) Active transport — molecules move against concentration gradient via carrier proteins using ATP energy.',
            explanation:
                'Marks breakdown: model description (2), diagram with labeled components (1), simple diffusion (1), facilitated diffusion (1), active transport (1).',
            marks: 6,
          ),
        ],
      ),
    ],
  );
}
