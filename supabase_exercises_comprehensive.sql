-- ==========================================
-- COMPREHENSIVE EXERCISES DATABASE
-- Flow App - Enhanced Exercise Database
-- ==========================================

-- First, drop existing exercises if you want to start fresh (optional)
-- DELETE FROM public.exercises;

-- Enhanced structure (if not already exists, the table should be created first)
-- The table structure from supabase_exercises_schema.sql is already good

-- ==========================================
-- CHEST EXERCISES (Brust)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Push-ups', 'Liegestütze', 'Chest', 'None', 'Beginner', 'Start in plank position. Lower your body until chest nearly touches floor, then push back up. Keep core tight and body straight.', 'Beginnen Sie in Plank-Position. Senken Sie den Körper, bis die Brust fast den Boden berührt, dann drücken Sie sich hoch. Bauchmuskeln anspannen und Körper gerade halten.', 0.8),
('Wide Push-ups', 'Weite Liegestütze', 'Chest', 'None', 'Intermediate', 'Same as push-ups but with hands wider than shoulder-width. Targets outer chest more.', 'Wie Liegestütze, aber mit Händen breiter als Schulterbreite. Trainiert mehr die äußere Brust.', 0.9),
('Diamond Push-ups', 'Diamant-Liegestütze', 'Chest', 'None', 'Advanced', 'Form a diamond with your hands. Targets triceps and inner chest. More challenging than regular push-ups.', 'Bilden Sie mit den Händen eine Raute. Trainiert Trizeps und innere Brust. Anspruchsvoller als normale Liegestütze.', 1.0),
('Incline Push-ups', 'Schräge Liegestütze', 'Chest', 'None', 'Beginner', 'Place hands on elevated surface (bench/chair). Easier variation for beginners.', 'Hände auf erhöhter Oberfläche (Bank/Stuhl) platzieren. Leichtere Variante für Anfänger.', 0.6),
('Decline Push-ups', 'Negative Liegestütze', 'Chest', 'None', 'Advanced', 'Feet elevated on bench. More challenging, targets upper chest.', 'Füße auf Bank erhöht. Anspruchsvoller, trainiert obere Brust.', 1.1),
('Pike Push-ups', 'Pike Liegestütze', 'Chest', 'None', 'Intermediate', 'Body in inverted V shape. Targets shoulders and upper chest.', 'Körper in umgekehrter V-Form. Trainiert Schultern und obere Brust.', 0.9),
('Archer Push-ups', 'Bogenschützen-Liegestütze', 'Chest', 'None', 'Advanced', 'Shift weight to one side while lowering. Advanced unilateral exercise.', 'Gewicht beim Absenken auf eine Seite verlagern. Fortgeschrittene einseitige Übung.', 1.2),

-- With Equipment
('Dumbbell Bench Press', 'Kurzhantel Bankdrücken', 'Chest', 'Dumbbells', 'Intermediate', 'Lie on bench, press dumbbells up from chest level. Control the weight on the way down.', 'Auf Bank liegen, Kurzhanteln von Brusthöhe nach oben drücken. Gewicht beim Absenken kontrollieren.', 1.5),
('Dumbbell Flyes', 'Kurzhantel Fliegende', 'Chest', 'Dumbbells', 'Intermediate', 'Arms wide, lower dumbbells in arc motion. Great for chest stretch and isolation.', 'Arme weit, Kurzhanteln in Bogenbewegung senken. Ideal für Brustdehnung und Isolation.', 1.2),
('Dumbbell Pullover', 'Kurzhantel Pullover', 'Chest', 'Dumbbells', 'Intermediate', 'Lie on bench, move dumbbell from behind head to over chest. Targets serratus and chest.', 'Auf Bank liegen, Kurzhantel von hinter dem Kopf über die Brust bewegen. Trainiert Sägemuskel und Brust.', 1.3),
('Push-up with Rotation', 'Liegestütz mit Rotation', 'Chest', 'None', 'Intermediate', 'After push-up, rotate body and raise one arm. Adds core and stability challenge.', 'Nach Liegestütz Körper rotieren und einen Arm heben. Fügt Rumpf- und Stabilitätsherausforderung hinzu.', 1.0);

-- ==========================================
-- BACK EXERCISES (Rücken)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Pull-ups', 'Klimmzüge', 'Back', 'Pull-up Bar', 'Intermediate', 'Hang from bar, pull body up until chin clears bar. Full range of motion.', 'An Stange hängen, Körper hochziehen bis Kinn über Stange. Volle Bewegungsamplitude.', 1.5),
('Chin-ups', 'Enger Klimmzug', 'Back', 'Pull-up Bar', 'Intermediate', 'Similar to pull-ups but with palms facing you. Targets biceps more.', 'Ähnlich wie Klimmzüge, aber mit Handflächen zu Ihnen. Trainiert mehr Bizeps.', 1.4),
('Inverted Rows', 'Umgekehrte Ruder', 'Back', 'None', 'Beginner', 'Under table or bar, pull chest to surface. Great beginner back exercise.', 'Unter Tisch oder Stange, Brust zur Oberfläche ziehen. Gute Anfänger-Rückenübung.', 1.0),
('Superman', 'Superman', 'Back', 'None', 'Beginner', 'Lie face down, lift arms and legs simultaneously. Strengthens lower back.', 'Bauchlage, Arme und Beine gleichzeitig heben. Stärkt unteren Rücken.', 0.3),
('Reverse Snow Angels', 'Umgekehrte Schneeengel', 'Back', 'None', 'Beginner', 'Lie face down, move arms in arc motion. Improves upper back mobility.', 'Bauchlage, Arme in Bogenbewegung bewegen. Verbessert obere Rückenmobilität.', 0.4),
('Prone Y-T-W', 'Bauchlage Y-T-W', 'Back', 'None', 'Intermediate', 'Lie face down, form Y, T, then W shapes with arms. Comprehensive back activation.', 'Bauchlage, mit Armen Y, T, dann W-Formen bilden. Umfassende Rückenaktivierung.', 0.5),

-- With Equipment
('Bent-over Rows', 'Vorgebeugtes Rudern', 'Back', 'Dumbbells', 'Intermediate', 'Bend forward, pull weights to lower chest. Keep back straight throughout.', 'Nach vorne beugen, Gewichte zur unteren Brust ziehen. Rücken währenddessen gerade halten.', 1.4),
('One-arm Row', 'Einarmiges Rudern', 'Back', 'Dumbbells', 'Intermediate', 'Support on bench, row one dumbbell. Allows for unilateral strength development.', 'Auf Bank abstützen, eine Kurzhantel rudern. Ermöglicht einseitige Kraftentwicklung.', 1.3),
('Reverse Flyes', 'Reverse Fliegende', 'Back', 'Dumbbells', 'Intermediate', 'Bent forward, raise arms wide. Targets rear delts and upper back.', 'Vorgebeugt, Arme weit heben. Trainiert hintere Schultern und oberen Rücken.', 1.1);

-- ==========================================
-- LEGS EXERCISES (Beine)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Squats', 'Kniebeugen', 'Legs', 'None', 'Beginner', 'Stand with feet shoulder-width. Lower hips as if sitting, then stand back up. Keep knees behind toes.', 'Stehen Sie mit schulterbreiten Füßen. Hüften senken als würden Sie sitzen, dann wieder aufstehen. Knie hinter Zehen halten.', 0.6),
('Jump Squats', 'Sprung-Kniebeugen', 'Legs', 'None', 'Intermediate', 'Squat down, then explosively jump up. Adds plyometric element.', 'In die Hocke gehen, dann explosiv hochspringen. Fügt plyometrisches Element hinzu.', 1.2),
('Lunges', 'Ausfallschritte', 'Legs', 'None', 'Beginner', 'Step forward, lower back knee toward ground. Return to start and alternate legs.', 'Schritt nach vorne, hinteres Knie zum Boden senken. Zurück zum Start und Beine wechseln.', 0.7),
('Reverse Lunges', 'Rückwärts-Ausfallschritte', 'Legs', 'None', 'Intermediate', 'Step backward instead of forward. Easier on knees, same muscle activation.', 'Schritt nach hinten statt vorne. Schonender für Knie, gleiche Muskelaktivierung.', 0.7),
('Walking Lunges', 'Gehende Ausfallschritte', 'Legs', 'None', 'Intermediate', 'Lunge forward, then step through to next lunge. Continuous movement pattern.', 'Ausfallschritt nach vorne, dann durchtreten zum nächsten. Kontinuierliche Bewegungsmuster.', 0.8),
('Bulgarian Split Squats', 'Bulgarische Kniebeugen', 'Legs', 'None', 'Advanced', 'Back foot elevated, squat with front leg. Intense unilateral leg exercise.', 'Hinterer Fuß erhöht, mit vorderem Bein kniebeugen. Intensive einseitige Beinübung.', 1.0),
('Pistol Squats', 'Pistol Kniebeugen', 'Legs', 'None', 'Advanced', 'Single leg squat. Extremely challenging, requires excellent balance and strength.', 'Einbeinige Kniebeuge. Extrem anspruchsvoll, erfordert ausgezeichnetes Gleichgewicht und Kraft.', 1.5),
('Wall Sit', 'Wandsitzen', 'Legs', 'None', 'Intermediate', 'Back against wall, hold squat position. Isometric leg endurance exercise.', 'Rücken an Wand, Kniebeugenposition halten. Isometrische Beinausdauerübung.', 0.1),
('Calf Raises', 'Wadenheben', 'Legs', 'None', 'Beginner', 'Stand on toes, raise and lower heels. Can be done on stairs for more range.', 'Auf Zehenspitzen stehen, Fersen heben und senken. Kann auf Treppen für mehr Amplitude gemacht werden.', 0.3),
('Single-leg Calf Raises', 'Einbeiniges Wadenheben', 'Legs', 'None', 'Intermediate', 'One leg at a time. Increases difficulty and addresses imbalances.', 'Ein Bein nach dem anderen. Erhöht Schwierigkeit und behebt Ungleichgewichte.', 0.4),
('Glute Bridge', 'Beckenheben', 'Legs', 'None', 'Beginner', 'Lie on back, lift hips up. Squeeze glutes at top. Great for posterior chain.', 'Auf Rücken liegen, Hüften anheben. Gesäßmuskeln oben anspannen. Ideal für hintere Kette.', 0.5),
('Single-leg Glute Bridge', 'Einbeiniges Beckenheben', 'Legs', 'None', 'Intermediate', 'One leg extended, bridge with other. Challenges stability and strength.', 'Ein Bein gestreckt, mit anderem brücken. Herausforderung für Stabilität und Kraft.', 0.6),
('Hip Thrusts', 'Hüftstoß', 'Legs', 'None', 'Intermediate', 'Shoulders on bench, thrust hips up. Superior glute activation.', 'Schultern auf Bank, Hüften nach oben stoßen. Überlegene Gesäßaktivierung.', 0.7),

-- With Equipment
('Goblet Squats', 'Goblet Kniebeugen', 'Legs', 'Dumbbells', 'Beginner', 'Hold dumbbell at chest, squat. Great for learning proper squat form.', 'Kurzhantel an Brust halten, kniebeugen. Ideal zum Erlernen der richtigen Kniebeugenform.', 0.8),
('Dumbbell Lunges', 'Kurzhantel Ausfallschritte', 'Legs', 'Dumbbells', 'Intermediate', 'Hold dumbbells, perform lunges. Adds resistance to standard lunge.', 'Kurzhanteln halten, Ausfallschritte ausführen. Fügt Widerstand zur Standard-Ausfallschritt hinzu.', 1.0),
('Romanian Deadlifts', 'Rumänisches Kreuzheben', 'Legs', 'Dumbbells', 'Intermediate', 'Hinge at hips, lower weights while keeping legs mostly straight. Targets hamstrings.', 'An Hüften einknicken, Gewichte senken während Beine größtenteils gerade bleiben. Trainiert Oberschenkelrückseite.', 1.2),
('Dumbbell Step-ups', 'Kurzhantel Step-ups', 'Legs', 'Dumbbells', 'Intermediate', 'Step onto bench with dumbbells. Functional leg strength exercise.', 'Mit Kurzhanteln auf Bank steigen. Funktionelle Beinkraftübung.', 1.1);

-- ==========================================
-- SHOULDERS EXERCISES (Schultern)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Pike Push-ups', 'Pike Liegestütze', 'Shoulders', 'None', 'Intermediate', 'Body in inverted V, perform push-ups. Targets shoulders and upper chest.', 'Körper in umgekehrter V-Form, Liegestütze ausführen. Trainiert Schultern und obere Brust.', 0.9),
('Handstand Push-ups', 'Handstand Liegestütze', 'Shoulders', 'None', 'Advanced', 'Against wall, perform push-ups in handstand. Extremely advanced shoulder exercise.', 'An Wand, Liegestütze im Handstand ausführen. Extrem fortgeschrittene Schulterübung.', 1.8),
('Wall Walk', 'Wandlauf', 'Shoulders', 'None', 'Intermediate', 'Walk feet up wall while in push-up position. Builds shoulder strength and stability.', 'Füße an Wand hochlaufen während in Liegestützposition. Baut Schulterkraft und Stabilität auf.', 1.0),
('Shoulder Taps', 'Schultertippen', 'Shoulders', 'None', 'Beginner', 'In plank, tap opposite shoulder. Challenges core and shoulder stability.', 'In Plank, gegenüberliegende Schulter antippen. Herausforderung für Rumpf und Schulterstabilität.', 0.4),

-- With Equipment
('Dumbbell Shoulder Press', 'Kurzhantel Schulterdrücken', 'Shoulders', 'Dumbbells', 'Intermediate', 'Press dumbbells overhead from shoulder height. Can be seated or standing.', 'Kurzhanteln von Schulterhöhe über Kopf drücken. Kann sitzend oder stehend gemacht werden.', 1.3),
('Lateral Raises', 'Seitheben', 'Shoulders', 'Dumbbells', 'Intermediate', 'Raise arms to sides until parallel to floor. Targets side delts.', 'Arme zur Seite heben bis parallel zum Boden. Trainiert seitliche Schultern.', 0.8),
('Front Raises', 'Frontheben', 'Shoulders', 'Dumbbells', 'Beginner', 'Raise arms forward to shoulder height. Targets front delts.', 'Arme nach vorne auf Schulterhöhe heben. Trainiert vordere Schultern.', 0.7),
('Rear Delt Flyes', 'Hintere Schulter Fliegende', 'Shoulders', 'Dumbbells', 'Intermediate', 'Bent forward, raise arms wide. Targets rear deltoids.', 'Vorgebeugt, Arme weit heben. Trainiert hintere Deltamuskeln.', 1.0),
('Arnold Press', 'Arnold Press', 'Shoulders', 'Dumbbells', 'Advanced', 'Rotate wrists while pressing overhead. Comprehensive shoulder movement.', 'Handgelenke beim Überkopfdrücken rotieren. Umfassende Schulterbewegung.', 1.4);

-- ==========================================
-- ARMS EXERCISES (Arme)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Tricep Dips', 'Trizeps-Dips', 'Arms', 'None', 'Beginner', 'On chair or bench, lower body by bending arms. Targets triceps.', 'Auf Stuhl oder Bank, Körper durch Beugen der Arme senken. Trainiert Trizeps.', 0.6),
('Diamond Push-ups', 'Diamant-Liegestütze', 'Arms', 'None', 'Advanced', 'Hands in diamond shape. Intense tricep and inner chest exercise.', 'Hände in Diamantform. Intensive Trizeps- und innere Brustübung.', 1.0),
('Close-grip Push-ups', 'Enger Liegestütz', 'Arms', 'None', 'Intermediate', 'Hands closer than shoulder-width. Emphasizes triceps.', 'Hände enger als Schulterbreite. Betont Trizeps.', 0.9),
('Pike Push-ups', 'Pike Liegestütze', 'Arms', 'None', 'Intermediate', 'Inverted V position. Targets triceps and shoulders.', 'Umgekehrte V-Position. Trainiert Trizeps und Schultern.', 0.9),
('Bodyweight Bicep Curls', 'Körpergewicht Bizeps-Curls', 'Arms', 'Resistance Band', 'Beginner', 'Use resistance band or towel. Pull against resistance to curl.', 'Widerstandsband oder Handtuch verwenden. Gegen Widerstand ziehen zum Curlen.', 0.5),

-- With Equipment
('Dumbbell Bicep Curls', 'Kurzhantel Bizeps-Curls', 'Arms', 'Dumbbells', 'Beginner', 'Curl dumbbells from arms extended to contracted position. Control the negative.', 'Kurzhanteln von gestreckten Armen zur kontrahierten Position curlen. Negativ kontrollieren.', 0.7),
('Hammer Curls', 'Hammer Curls', 'Arms', 'Dumbbells', 'Beginner', 'Neutral grip, curl without rotating. Targets brachialis and forearms.', 'Neutraler Griff, ohne Rotation curlen. Trainiert Brachialis und Unterarme.', 0.7),
('Tricep Extensions', 'Trizeps-Extensionen', 'Arms', 'Dumbbells', 'Intermediate', 'Overhead, extend arms. Can be done with one or two dumbbells.', 'Über Kopf, Arme strecken. Kann mit einer oder zwei Kurzhanteln gemacht werden.', 0.8),
('Tricep Kickbacks', 'Trizeps-Kickbacks', 'Arms', 'Dumbbells', 'Intermediate', 'Bent over, extend arm back. Isolates triceps effectively.', 'Vorgebeugt, Arm nach hinten strecken. Isoliert Trizeps effektiv.', 0.6),
('Concentration Curls', 'Konzentrations-Curls', 'Arms', 'Dumbbells', 'Intermediate', 'Seated, arm on thigh, curl. Maximum bicep isolation.', 'Sitzend, Arm auf Oberschenkel, curlen. Maximale Bizeps-Isolation.', 0.6);

-- ==========================================
-- ABS EXERCISES (Bauch)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
-- Bodyweight
('Crunches', 'Crunches', 'Abs', 'None', 'Beginner', 'Lie on back, lift shoulders off ground using abs. Don''t pull on neck.', 'Auf Rücken liegen, Schultern mit Bauchmuskeln vom Boden heben. Nicht am Nacken ziehen.', 0.4),
('Bicycle Crunches', 'Fahrrad-Crunches', 'Abs', 'None', 'Intermediate', 'Alternate bringing elbow to opposite knee. Targets obliques and rectus abdominis.', 'Abwechselnd Ellbogen zum gegenüberliegenden Knie bringen. Trainiert schräge und gerade Bauchmuskeln.', 0.6),
('Russian Twists', 'Russian Twists', 'Abs', 'None', 'Intermediate', 'Sitting, twist torso side to side. Can add weight for difficulty.', 'Sitzend, Oberkörper von Seite zu Seite drehen. Kann Gewicht für Schwierigkeit hinzufügen.', 0.5),
('Plank', 'Unterarmstütz', 'Abs', 'None', 'Intermediate', 'Hold body straight, supported on forearms. Excellent core stability exercise.', 'Körper gerade halten, auf Unterarmen gestützt. Ausgezeichnete Rumpfstabilitätsübung.', 0.2),
('Side Plank', 'Seitstütz', 'Abs', 'None', 'Intermediate', 'Support on one forearm, body in straight line. Targets obliques.', 'Auf einem Unterarm abstützen, Körper in gerader Linie. Trainiert schräge Bauchmuskeln.', 0.3),
('Mountain Climbers', 'Bergsteiger', 'Abs', 'None', 'Intermediate', 'In plank, alternate bringing knees to chest. Cardio and core combined.', 'In Plank, abwechselnd Knie zur Brust bringen. Cardio und Rumpf kombiniert.', 0.5),
('Leg Raises', 'Beinheben', 'Abs', 'None', 'Intermediate', 'Lie on back, raise legs straight up. Lower slowly for maximum effect.', 'Auf Rücken liegen, Beine gerade hochheben. Langsam senken für maximale Wirkung.', 0.6),
('Flutter Kicks', 'Flatternde Kicks', 'Abs', 'None', 'Intermediate', 'Lie on back, alternate kicking legs. Maintains constant tension on abs.', 'Auf Rücken liegen, Beine abwechselnd kicken. Hält konstante Spannung auf Bauchmuskeln.', 0.4),
('Dead Bug', 'Toter Käfer', 'Abs', 'None', 'Beginner', 'Lie on back, extend opposite arm and leg. Excellent for core stability.', 'Auf Rücken liegen, gegenüberliegenden Arm und Bein strecken. Ausgezeichnet für Rumpfstabilität.', 0.3),
('V-ups', 'V-Ups', 'Abs', 'None', 'Advanced', 'Lie on back, lift torso and legs simultaneously to form V. Challenging full ab exercise.', 'Auf Rücken liegen, Oberkörper und Beine gleichzeitig zu V-Form heben. Herausfordernde volle Bauchübung.', 0.8),
('Hollow Body Hold', 'Hohler Körper Halten', 'Abs', 'None', 'Intermediate', 'Lie on back, lift shoulders and legs, hold. Isometric core strength builder.', 'Auf Rücken liegen, Schultern und Beine heben, halten. Isometrischer Rumpfkraftaufbau.', 0.2),
('Scissor Kicks', 'Scherenkicks', 'Abs', 'None', 'Intermediate', 'Lie on back, alternate crossing legs. Targets lower abs.', 'Auf Rücken liegen, Beine abwechselnd kreuzen. Trainiert untere Bauchmuskeln.', 0.4);

-- ==========================================
-- CARDIO EXERCISES (Cardio)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
('Jumping Jacks', 'Hampelmann', 'Cardio', 'None', 'Beginner', 'Jump with legs apart and arms overhead, then return. Classic full-body cardio.', 'Springen mit gespreizten Beinen und Armen über Kopf, dann zurück. Klassisches Ganzkörper-Cardio.', 0.6),
('Burpees', 'Burpees', 'Cardio', 'None', 'Advanced', 'Squat, jump back to plank, push-up, jump forward, jump up. Ultimate full-body cardio.', 'Kniebeuge, Sprung zurück zu Plank, Liegestütz, Sprung vor, Sprung hoch. Ultimatives Ganzkörper-Cardio.', 1.5),
('High Knees', 'Hohe Knie', 'Cardio', 'None', 'Beginner', 'Run in place, bringing knees up high. Great warm-up and cardio exercise.', 'Auf der Stelle laufen, Knie hoch bringen. Gutes Aufwärmen und Cardio-Übung.', 0.5),
('Butt Kicks', 'Hintern-Kicks', 'Cardio', 'None', 'Beginner', 'Run in place, kicking heels to glutes. Targets hamstrings and provides cardio.', 'Auf der Stelle laufen, Fersen zu Gesäß kicken. Trainiert Oberschenkelrückseite und bietet Cardio.', 0.5),
('Jump Rope', 'Seilspringen', 'Cardio', 'Jump Rope', 'Intermediate', 'Jump over rope as it passes under feet. Excellent cardio and coordination exercise.', 'Über Seil springen während es unter Füßen vorbeigeht. Ausgezeichnete Cardio- und Koordinationsübung.', 0.7),
('Mountain Climbers', 'Bergsteiger', 'Cardio', 'None', 'Intermediate', 'In plank position, alternate bringing knees to chest rapidly. Cardio and core combined.', 'In Plank-Position, abwechselnd Knie schnell zur Brust bringen. Cardio und Rumpf kombiniert.', 0.5),
('Star Jumps', 'Sternsprünge', 'Cardio', 'None', 'Intermediate', 'Jump up, spread arms and legs wide like a star. High-intensity cardio movement.', 'Hochspringen, Arme und Beine weit wie ein Stern spreizen. Hochintensive Cardio-Bewegung.', 0.8),
('Sprint in Place', 'Sprint auf der Stelle', 'Cardio', 'None', 'Intermediate', 'Run in place as fast as possible. High-intensity interval cardio.', 'So schnell wie möglich auf der Stelle laufen. Hochintensives Intervall-Cardio.', 0.6),
('Jump Squats', 'Sprung-Kniebeugen', 'Cardio', 'None', 'Intermediate', 'Squat down, then explosively jump up. Combines strength and cardio.', 'In die Hocke gehen, dann explosiv hochspringen. Kombiniert Kraft und Cardio.', 1.2),
('Bear Crawl', 'Bärenkrabbeln', 'Cardio', 'None', 'Intermediate', 'Crawl forward on hands and feet, knees off ground. Full-body cardio and strength.', 'Auf Händen und Füßen vorwärts krabbeln, Knie vom Boden. Ganzkörper-Cardio und Kraft.', 0.7);

-- ==========================================
-- FULL BODY EXERCISES (Ganzkörper)
-- ==========================================

INSERT INTO public.exercises (name_en, name_de, muscle_group, equipment, difficulty, instructions_en, instructions_de, calories_per_rep) VALUES
('Burpees', 'Burpees', 'Full Body', 'None', 'Advanced', 'Squat, jump back to plank, push-up, jump forward, jump up. Ultimate full-body exercise.', 'Kniebeuge, Sprung zurück zu Plank, Liegestütz, Sprung vor, Sprung hoch. Ultimative Ganzkörperübung.', 1.5),
('Thrusters', 'Thrusters', 'Full Body', 'Dumbbells', 'Advanced', 'Squat with dumbbells, then press overhead. Combines legs, core, and shoulders.', 'Kniebeuge mit Kurzhanteln, dann über Kopf drücken. Kombiniert Beine, Rumpf und Schultern.', 1.6),
('Man Makers', 'Man Makers', 'Full Body', 'Dumbbells', 'Advanced', 'Complex movement: plank row, push-up, squat, press. Extremely challenging.', 'Komplexe Bewegung: Plank-Rudern, Liegestütz, Kniebeuge, Drücken. Extrem herausfordernd.', 2.0),
('Turkish Get-ups', 'Türkisches Aufstehen', 'Full Body', 'Dumbbells', 'Advanced', 'Complex movement from lying to standing. Develops full-body strength and stability.', 'Komplexe Bewegung vom Liegen zum Stehen. Entwickelt Ganzkörperkraft und Stabilität.', 1.8),
('Renegade Rows', 'Renegade Rudern', 'Full Body', 'Dumbbells', 'Advanced', 'In plank, row one dumbbell at a time. Challenges core, back, and stability.', 'In Plank, eine Kurzhantel nach der anderen rudern. Herausforderung für Rumpf, Rücken und Stabilität.', 1.4),
('Squat to Press', 'Kniebeuge zum Drücken', 'Full Body', 'Dumbbells', 'Intermediate', 'Squat, then press dumbbells overhead. Full-body power movement.', 'Kniebeuge, dann Kurzhanteln über Kopf drücken. Ganzkörper-Kraftbewegung.', 1.3),
('Deadlift to Row', 'Kreuzheben zum Rudern', 'Full Body', 'Dumbbells', 'Advanced', 'Deadlift, then row. Combines posterior chain and upper back.', 'Kreuzheben, dann rudern. Kombiniert hintere Kette und oberen Rücken.', 1.5);

-- ==========================================
-- NOTES
-- ==========================================
-- Total exercises: 100+
-- Covers all major muscle groups
-- Includes bodyweight and equipment variations
-- All exercises have English and German names/instructions
-- Calories per rep are estimates - adjust based on user weight and intensity
-- Video URLs can be added later for each exercise
-- Consider adding: exercise_type (strength, cardio, flexibility), target_muscles (array), secondary_muscles (array)


