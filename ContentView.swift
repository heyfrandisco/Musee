import SwiftUI
import AVFoundation

class MetronomeAudioPlayer: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var firstBeatPlayer: AVAudioPlayerNode?
    private var secondBeatPlayer: AVAudioPlayerNode?
    
    var beat: Int?
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            return
        }
        
        firstBeatPlayer = AVAudioPlayerNode()
        secondBeatPlayer = AVAudioPlayerNode()
        
        audioEngine.attach(firstBeatPlayer!)
        audioEngine.attach(secondBeatPlayer!)
        
        audioEngine.connect(firstBeatPlayer!, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(secondBeatPlayer!, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func playSound() {
        guard let beat = beat else {
            return
        }
        
        let playerToUse = (beat == 1) ? firstBeatPlayer : secondBeatPlayer
        
        if let player = playerToUse {
            do {
                let audioFile = try AVAudioFile(forReading: Bundle.main.url(forResource: (beat == 1) ? "first_beat" : "second_beat", withExtension: "wav")!)
                player.scheduleFile(audioFile, at: nil, completionHandler: nil)
                
                player.volume = (beat == 1) ? 1.0 : 0.6
                
                try audioEngine?.start()
                player.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
    }
}


class FirstBeat: NSObject, AVAudioPlayerDelegate {
    var audio: AVAudioPlayer?
    
    override init() {
        super.init()
        setupAudioPlayer(resource: "AUDIO/first_beat")
    }
    
    func setupAudioPlayer(resource: String) {
        guard let soundURL = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        
        do {
            audio = try AVAudioPlayer(contentsOf: soundURL)
            audio?.delegate = self
            audio?.prepareToPlay()
        } catch {
            print("Error loading sound file: \(error.localizedDescription)")
        }
    }
    
    func playAudio() {
        audio?.play()
    }
}

class SecondBeat: FirstBeat {
    override init() {
        super.init()
        setupAudioPlayer(resource: "AUDIO/second_beat")
    }
}


struct MetronomeCircleView: View {
    var full = false
    
    var body: some View {
        // let gradient = LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
        
        let gradient = Color.indigo
        
        if full {
            Circle()
                .fill(gradient)
                .frame(width: 50, height: 50)
        } else {
            Circle()
                .stroke(gradient, lineWidth: 2)
                .frame(width: 50, height: 50)
        }
    }
}


struct VisualMetronome: View {
    @ObservedObject var metronomeAudioPlayer = MetronomeAudioPlayer()
    var bpm: Int
    
    @State private var position = 1
    
    var body: some View {
        HStack {
            MetronomeCircleView(full: position == 1).padding()
            MetronomeCircleView(full: position == 2).padding()
            MetronomeCircleView(full: position == 3).padding()
            MetronomeCircleView(full: position == 4).padding()
        }
        .onReceive(Timer.publish(every: 60.0 / Double(bpm), on: .main, in: .common).autoconnect()) { _ in
            self.position = (self.position % 4) + 1
            
            self.metronomeAudioPlayer.beat = self.position
            self.metronomeAudioPlayer.playSound()
        }
    }
}


class Metronome: ObservableObject {
    @Published var bpm_h = 0
    @Published var bpm_d = 0
    @Published var bpm_u = 0
    var metronome_timer: Timer?
    
    func startMetronome() {
        let bpm = bpm_h * 100 + bpm_d * 10 + bpm_u
        let timeInterval = 60.0 / Double(bpm)
        metronome_timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(handleMetronomeTick), userInfo: nil, repeats: true)
    }
    
    @objc func handleMetronomeTick() {
        
    }
    
    func stopMetronome() {
        metronome_timer?.invalidate()
        metronome_timer = nil
        bpm_h = 0
        bpm_d = 0
        bpm_u = 0
    }
}

struct DrumSound {
    let name: String
    let audioFile: String
    var isActive: Bool
}


struct ContentView: View {
    @StateObject private var metronome = Metronome()
    
    var body: some View {
        ZStack {
            VStack {
                Text("Musee.")
                    .font(.system(size: 50))
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                HStack{
                    Text("\(metronome.bpm_h * 100 + metronome.bpm_d * 10 + metronome.bpm_u)")
                        .foregroundColor(.purple)
                        .font(.system(size: 80))
                        .fontWeight(.semibold)
                    
                    Text("bpm")
                        .foregroundColor(.indigo)
                        .font(.system(size: 30))
                        .fontWeight(.semibold)
                        .padding([.top], 30)
                }
                .padding()
                
                HStack {
                    Picker("Hundreds", selection: $metronome.bpm_h) {
                        ForEach(0..<3) { number in
                            Text("\(number)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    Picker("Tens", selection: $metronome.bpm_d) {
                        ForEach(0..<10) { number in
                            Text("\(number)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    Picker("Units", selection: $metronome.bpm_u) {
                        ForEach(0..<10) { number in
                            Text("\(number)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                }
                .padding()
                
                HStack{
                    
                    Button(action: {
                        metronome.startMetronome()
                    }) {
                        Text("Start Metronome")
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(15)
                    .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
                    .scaleEffect(metronome.metronome_timer == nil ? 1.0 : 0.9)
                    .padding()
                    
                    Button(action: {
                        metronome.stopMetronome()
                    }) {
                        Text("Stop Metronome")
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.purple, Color.indigo]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(15)
                    .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
                    .scaleEffect(metronome.metronome_timer == nil ? 1.0 : 0.9)
                    .padding()
                    Spacer()
                    
                }
                
                Spacer()
                
                HStack {
                    VisualMetronome(bpm: metronome.bpm_h * 100 + metronome.bpm_d * 10 + metronome.bpm_u).padding()
                }
                
                Spacer()
                
                /*
                VStack {
                    var drumSounds: [[DrumSound]] = [
                           [DrumSound(name: "Kick", audioFile: "musee_kick.mp3", isActive: false), DrumSound(name: "Clap", audioFile: "musee_clap.mp3", isActive: false), DrumSound(name: "Hat", audioFile: "musee_hat.mp3", isActive: false)],
                           [DrumSound(name: "Kick", audioFile: "musee_kick.mp3", isActive: false), DrumSound(name: "Clap", audioFile: "musee_clap.mp3", isActive: false), DrumSound(name: "Hat", audioFile: "musee_hat.mp3", isActive: false)],
                           [DrumSound(name: "Kick", audioFile: "musee_kick.mp3", isActive: false), DrumSound(name: "Clap", audioFile: "musee_clap.mp3", isActive: false), DrumSound(name: "Hat", audioFile: "musee_hat.mp3", isActive: false)],
                           [DrumSound(name: "Kick", audioFile: "musee_kick.mp3", isActive: false), DrumSound(name: "Clap", audioFile: "musee_clap.mp3", isActive: false), DrumSound(name: "Hat", audioFile: "musee_hat.mp3", isActive: false)]
                       ]
                    
                    var audioPlayer: AVAudioPlayer?
                        
                            VStack(spacing: 20) {
                                ForEach(0..<4) { row in
                                    HStack(spacing: 20) {
                                        ForEach(0..<3) { col in
                                            Button(action: {
                                                // Toggle the isActive property of the drum sound
                                                drumSounds[row][col].isActive.toggle()
                                                // Play the audio file associated with the drum sound
                                                if let audioFile = Bundle.main.path(forResource: drumSounds[row][col].audioFile, ofType: nil) {
                                                    do {
                                                        // Initialize the audio player if it's not already initialized
                                                        if audioPlayer == nil {
                                                            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioFile))
                                                            audioPlayer?.prepareToPlay()
                                                        }
                                                        // Play the audio file
                                                        audioPlayer?.play()
                                                    } catch {
                                                        print("Error playing audio file: \(error.localizedDescription)")
                                                    }
                                                }
                                            }) {
                                                Text(drumSounds[row][col].name)
                                                    .foregroundColor(drumSounds[row][col].isActive ? .white : .black)
                                                    .padding()
                                                    .background(drumSounds[row][col].isActive ? Color.blue : Color.indigo)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                */
            }
            
            .padding()
            Spacer()
        }
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
