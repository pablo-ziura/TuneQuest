import AVFoundation
import SwiftUI

struct GameOnePlayerView: View {
    @State private var player: AVPlayer? // Reproductor AV
    @State private var isPlaying = false // Estado de reproducción
    @State private var previewURL: URL? // URL de la preview obtenida

    var body: some View {
        VStack {
            Button(action: {
                if let player = player {
                    // Alternar entre reproducir y pausar
                    if player.timeControlStatus == .playing {
                        player.pause()
                        isPlaying = false
                    } else {
                        player.play()
                        isPlaying = true
                    }
                } else if let url = previewURL {
                    // Inicializar AVPlayer con la URL de preview y comenzar reproducción
                    player = AVPlayer(url: url)
                    player?.play()
                    isPlaying = true
                }
            }) {
                Text(isPlaying ? "Pausar Preview" : "Reproducir Preview")
            }
        }
        .onAppear {
            // 1. Obtener la información de la canción (ejemplo: ID 3135556)
            let trackId = 3135556
            let apiURL = URL(string: "https://api.deezer.com/track/\(trackId)")!

            // 2. Llamar a la API de Deezer (request HTTP) para obtener los datos de la pista
            URLSession.shared.dataTask(with: apiURL) { data, _, error in
                guard let data = data, error == nil else { return }
                // 3. Parsear el JSON para extraer el campo "preview"
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let previewString = json["preview"] as? String,
                   let url = URL(string: previewString) {
                    // 4. Guardar la URL de preview en el estado (en el hilo principal)
                    DispatchQueue.main.async {
                        self.previewURL = url
                    }
                }
            }
            .resume()
        }
    }
}
