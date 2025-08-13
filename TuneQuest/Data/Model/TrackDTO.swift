import Foundation

struct TrackDTO: Codable, Equatable, Hashable, Sendable {
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
    let preview: String?
    let bpm: Double?
    let gain: Double?
    let availableCountries: [String]?
    let contributors: [ArtistDTO]?
    let md5Image: String?
    let trackToken: String?
    let artist: ArtistDTO?
    let album: AlbumDTO?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id, readable, title
        case titleShort = "title_short"
        case titleVersion = "title_version"
        case isrc, link, share, duration
        case trackPosition = "track_position"
        case diskNumber = "disk_number"
        case rank
        case releaseDate = "release_date"
        case explicitLyrics = "explicit_lyrics"
        case explicitContentLyrics = "explicit_content_lyrics"
        case explicitContentCover = "explicit_content_cover"
        case preview, bpm, gain
        case availableCountries = "available_countries"
        case contributors
        case md5Image = "md5_image"
        case trackToken = "track_token"
        case artist, album, type
    }

    init(
        id: Int? = nil,
        readable: Bool? = nil,
        title: String? = nil,
        titleShort: String? = nil,
        titleVersion: String? = nil,
        isrc: String? = nil,
        link: String? = nil,
        share: String? = nil,
        duration: Int? = nil,
        trackPosition: Int? = nil,
        diskNumber: Int? = nil,
        rank: Int? = nil,
        releaseDate: String? = nil,
        explicitLyrics: Bool? = nil,
        explicitContentLyrics: Int? = nil,
        explicitContentCover: Int? = nil,
        preview: String? = nil,
        bpm: Double? = nil,
        gain: Double? = nil,
        availableCountries: [String]? = nil,
        contributors: [ArtistDTO]? = nil,
        md5Image: String? = nil,
        trackToken: String? = nil,
        artist: ArtistDTO? = nil,
        album: AlbumDTO? = nil,
        type: String? = nil
    ) {
        self.id = id
        self.readable = readable
        self.title = title
        self.titleShort = titleShort
        self.titleVersion = titleVersion
        self.isrc = isrc
        self.link = link
        self.share = share
        self.duration = duration
        self.trackPosition = trackPosition
        self.diskNumber = diskNumber
        self.rank = rank
        self.releaseDate = releaseDate
        self.explicitLyrics = explicitLyrics
        self.explicitContentLyrics = explicitContentLyrics
        self.explicitContentCover = explicitContentCover
        self.preview = preview
        self.bpm = bpm
        self.gain = gain
        self.availableCountries = availableCountries
        self.contributors = contributors
        self.md5Image = md5Image
        self.trackToken = trackToken
        self.artist = artist
        self.album = album
        self.type = type
    }
}

struct AlbumDTO: Codable, Equatable, Hashable, Sendable {
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

    enum CodingKeys: String, CodingKey {
        case id, title, link, cover
        case coverSmall = "cover_small"
        case coverMedium = "cover_medium"
        case coverBig = "cover_big"
        case coverXl = "cover_xl"
        case md5Image = "md5_image"
        case releaseDate = "release_date"
        case tracklist, type
    }
}

struct ArtistDTO: Codable, Equatable, Hashable, Sendable {
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

    enum CodingKeys: String, CodingKey {
        case id, name, link, share, picture
        case pictureSmall = "picture_small"
        case pictureMedium = "picture_medium"
        case pictureBig = "picture_big"
        case pictureXl = "picture_xl"
        case radio, tracklist, type, role
    }
}
