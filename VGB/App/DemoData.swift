import Foundation
import SwiftData

/// Seed data for screenshot/demo: 50+ AAA current-gen games.
/// Launch with -SeedDemoData to replace all games with this set.
enum DemoData {

    /// IGDB cover image IDs (t_thumb) so list/detail show real thumbnails.
    private static let coverImageIDs = [
        "co4jni", "co2lv2", "co3u2a", "co2lzd", "co2lze", "co2lzf", "co1rje", "co2lbd",
        "co2lbe", "co2lbf", "co2lbg", "co2lbh", "co2lbi", "co2lbj", "co2lbk", "co2lbl",
        "co2lbm", "co2lbn", "co2lbo", "co2lbp", "co2lbq", "co2lbr", "co2lbs", "co2lbt",
    ]

    struct Entry {
        let title: String
        let platform: String
        let status: GameStatus
        let priorityPosition: Int
        let genre: String?
        let developer: String?
        let igdbRating: Int?
        let personalRating: Int? // for completed/dropped
        let coverImageID: String?
    }

    static let entries: [Entry] = {
        var list: [Entry] = []
        var pos = 0

        // 2 Playing
        list.append(Entry(title: "Dragon's Dogma 2", platform: "PS5", status: .playing, priorityPosition: pos, genre: "Action RPG", developer: "Capcom", igdbRating: 87, personalRating: nil, coverImageID: coverImageIDs[pos % coverImageIDs.count])); pos += 1
        list.append(Entry(title: "Rise of the Ronin", platform: "PS5", status: .playing, priorityPosition: pos, genre: "Action", developer: "Team Ninja", igdbRating: 76, personalRating: nil, coverImageID: coverImageIDs[pos % coverImageIDs.count])); pos += 1

        // 14 Backlog
        let backlog = [
            ("Final Fantasy VII Rebirth", "PS5", "RPG", "Square Enix", 92),
            ("Helldivers 2", "PS5", "Shooter", "Arrowhead", 82),
            ("Prince of Persia: The Lost Crown", "Switch", "Action", "Ubisoft", 87),
            ("Like a Dragon: Infinite Wealth", "PS5", "RPG", "Ryu Ga Gotoku", 89),
            ("Tekken 8", "PS5", "Fighting", "Bandai Namco", 90),
            ("Persona 3 Reload", "PS5", "RPG", "Atlus", 88),
            ("Banishers: Ghosts of New Eden", "PS5", "Action RPG", "Don't Nod", 78),
            ("Suicide Squad: Kill the Justice League", "PS5", "Shooter", "Rocksteady", 60),
            ("Skull and Bones", "PS5", "Action", "Ubisoft", 62),
            ("Mario vs. Donkey Kong", "Switch", "Puzzle", "Nintendo", 76),
            ("Granblue Fantasy: Relink", "PS5", "RPG", "Cygames", 80),
            ("Pacific Drive", "PS5", "Survival", "Ironwood", 77),
            ("Tomb Raider I–III Remastered", "PS5", "Adventure", "Aspyr", 72),
            ("Alone in the Dark", "PS5", "Horror", "Pieces Interactive", 65),
        ]
        for (title, platform, genre, dev, igdb) in backlog {
            list.append(Entry(title: title, platform: platform, status: .backlog, priorityPosition: pos, genre: genre, developer: dev, igdbRating: igdb, personalRating: nil, coverImageID: coverImageIDs[pos % coverImageIDs.count])); pos += 1
        }

        // 30 Completed
        let completed: [(String, String, String, String, Int, Int)] = [
            ("Elden Ring", "PS5", "Action RPG", "FromSoftware", 96, 95),
            ("God of War Ragnarök", "PS5", "Action", "Santa Monica", 94, 93),
            ("The Legend of Zelda: Tears of the Kingdom", "Switch", "Action Adventure", "Nintendo", 96, 97),
            ("Baldur's Gate 3", "PS5", "RPG", "Larian", 96, 98),
            ("Marvel's Spider-Man 2", "PS5", "Action", "Insomniac", 90, 91),
            ("Horizon Forbidden West", "PS5", "Action RPG", "Guerrilla", 88, 88),
            ("Resident Evil 4 Remake", "PS5", "Horror", "Capcom", 93, 92),
            ("Alan Wake 2", "PS5", "Horror", "Remedy", 89, 90),
            ("Armored Core VI: Fires of Rubicon", "PS5", "Action", "FromSoftware", 86, 87),
            ("Lies of P", "PS5", "Action RPG", "Neowiz", 84, 85),
            ("Dead Space", "PS5", "Horror", "Motive", 89, 88),
            ("Starfield", "XSX", "RPG", "Bethesda", 83, 82),
            ("Final Fantasy XVI", "PS5", "RPG", "Square Enix", 87, 86),
            ("Cyberpunk 2077", "PS5", "RPG", "CD Projekt", 86, 85),
            ("Hogwarts Legacy", "PS5", "Action RPG", "Avalanche", 84, 83),
            ("Diablo IV", "PS5", "RPG", "Blizzard", 88, 84),
            ("Star Wars Jedi: Survivor", "PS5", "Action", "Respawn", 85, 86),
            ("Ratchet & Clank: Rift Apart", "PS5", "Action", "Insomniac", 88, 87),
            ("Demon's Souls", "PS5", "Action RPG", "Bluepoint", 92, 91),
            ("Returnal", "PS5", "Shooter", "Housemarque", 86, 88),
            ("Ghost of Tsushima", "PS5", "Action", "Sucker Punch", 83, 90),
            ("Metroid Dread", "Switch", "Action", "MercurySteam", 88, 89),
            ("Hades", "Switch", "Roguelike", "Supergiant", 93, 94),
            ("Forza Horizon 5", "XSX", "Racing", "Playground", 92, 88),
            ("Halo Infinite", "XSX", "Shooter", "343 Industries", 87, 80),
            ("The Last of Us Part II", "PS5", "Action", "Naughty Dog", 93, 91),
            ("Sekiro: Shadows Die Twice", "PS5", "Action", "FromSoftware", 90, 92),
            ("Red Dead Redemption 2", "PS5", "Action Adventure", "Rockstar", 97, 95),
            ("Mass Effect Legendary Edition", "PS5", "RPG", "BioWare", 91, 90),
            ("Elden Ring: Shadow of the Erdtree", "PS5", "Action RPG", "FromSoftware", 95, 94),
        ]
        for (title, platform, genre, dev, igdb, personal) in completed {
            list.append(Entry(title: title, platform: platform, status: .completed, priorityPosition: pos, genre: genre, developer: dev, igdbRating: igdb, personalRating: personal, coverImageID: coverImageIDs[pos % coverImageIDs.count])); pos += 1
        }

        // 4 Dropped (poorly received)
        let dropped: [(String, String, String?, Int?)] = [
            ("The Lord of the Rings: Gollum", "PS5", "Action", 34),
            ("Redfall", "XSX", "Shooter", 56),
            ("Babylon's Fall", "PS5", "Action", 41),
            ("Saints Row", "PS5", "Action", 62),
        ]
        for (title, platform, genre, igdb) in dropped {
            list.append(Entry(title: title, platform: platform, status: .dropped, priorityPosition: pos, genre: genre, developer: nil, igdbRating: igdb, personalRating: igdb.map { max(20, min(50, $0)) }, coverImageID: coverImageIDs[pos % coverImageIDs.count])); pos += 1
        }

        return list
    }()

    static func seed(into context: ModelContext) {
        let descriptor = FetchDescriptor<Game>()
        guard let existing = try? context.fetch(descriptor) else { return }
        for game in existing {
            context.delete(game)
        }
        try? context.save()

        for entry in entries {
            let game = Game(
                title: entry.title,
                platform: entry.platform,
                status: entry.status,
                priorityPosition: entry.priorityPosition
            )
            game.genre = entry.genre
            game.developer = entry.developer
            game.igdbRating = entry.igdbRating
            game.personalRating = entry.personalRating
            game.releaseDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
            if let id = entry.coverImageID {
                game.coverImageURL = "https://images.igdb.com/igdb/image/upload/t_thumb/\(id).jpg"
            }
            context.insert(game)
        }
        try? context.save()
    }
}
