import Foundation

struct Track: Equatable, Hashable, Sendable {
    let id: Int?
    let readable: Bool?
    let title: String?
    let titleShort: String?
    let titleVersion: String?
    let isrc: String?
    let link: String?
    let share: String?
    let duration: Int?
    let trackPosition: Int?
    let diskNumber: Int?
    let rank: Int?
    let releaseDate: String?
    let explicitLyrics: Bool?
    let explicitContentLyrics: Int?
    let explicitContentCover: Int?
    let preview: URL?
    let bpm: Int?
    let gain: Double?
    let availableCountries: [String]?
    let contributors: [Artist]?
    let md5Image: String?
    let trackToken: String?
    let artist: Artist?
    let album: Album?
    let type: String?
}

struct Album: Equatable, Hashable, Sendable {
    let id: Int?
    let title: String?
    let link: String?
    let cover: String?
    let coverSmall: String?
    let coverMedium: String?
    let coverBig: String?
    let coverXl: String?
    let md5Image: String?
    let releaseDate: String?
    let tracklist: String?
    let type: String?
}

struct Artist: Equatable, Hashable, Sendable {
    let id: Int?
    let name: String?
    let link: String?
    let share: String?
    let picture: String?
    let pictureSmall: String?
    let pictureMedium: String?
    let pictureBig: String?
    let pictureXl: String?
    let radio: Bool?
    let tracklist: String?
    let type: String?
    let role: String?
}

extension Track {
    init(dto: TrackDTO) {
        id = dto.id
        readable = dto.readable
        title = dto.title
        titleShort = dto.titleShort
        titleVersion = dto.titleVersion
        isrc = dto.isrc
        link = dto.link
        share = dto.share
        duration = dto.duration
        trackPosition = dto.trackPosition
        diskNumber = dto.diskNumber
        rank = dto.rank
        releaseDate = dto.releaseDate
        explicitLyrics = dto.explicitLyrics
        explicitContentLyrics = dto.explicitContentLyrics
        explicitContentCover = dto.explicitContentCover
        preview = dto.preview.flatMap(URL.init(string:))
        bpm = dto.bpm
        gain = dto.gain
        availableCountries = dto.availableCountries
        contributors = dto.contributors?.map(Artist.init(dto:))
        md5Image = dto.md5Image
        trackToken = dto.trackToken
        artist = dto.artist.map(Artist.init(dto:))
        album = dto.album.map(Album.init(dto:))
        type = dto.type
    }
}

extension Album {
    init(dto: AlbumDTO) {
        id = dto.id
        title = dto.title
        link = dto.link
        cover = dto.cover
        coverSmall = dto.coverSmall
        coverMedium = dto.coverMedium
        coverBig = dto.coverBig
        coverXl = dto.coverXl
        md5Image = dto.md5Image
        releaseDate = dto.releaseDate
        tracklist = dto.tracklist
        type = dto.type
    }
}

extension Artist {
    init(dto: ArtistDTO) {
        id = dto.id
        name = dto.name
        link = dto.link
        share = dto.share
        picture = dto.picture
        pictureSmall = dto.pictureSmall
        pictureMedium = dto.pictureMedium
        pictureBig = dto.pictureBig
        pictureXl = dto.pictureXl
        radio = dto.radio
        tracklist = dto.tracklist
        type = dto.type
        role = dto.role
    }
}

extension Track {
    init(previewURL: URL) {
        self.init(
            id: nil,
            readable: nil,
            title: nil,
            titleShort: nil,
            titleVersion: nil,
            isrc: nil,
            link: nil,
            share: nil,
            duration: nil,
            trackPosition: nil,
            diskNumber: nil,
            rank: nil,
            releaseDate: nil,
            explicitLyrics: nil,
            explicitContentLyrics: nil,
            explicitContentCover: nil,
            preview: previewURL,
            bpm: nil,
            gain: nil,
            availableCountries: nil,
            contributors: nil,
            md5Image: nil,
            trackToken: nil,
            artist: nil,
            album: nil,
            type: nil
        )
    }
}
