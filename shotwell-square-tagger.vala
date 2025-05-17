using Sqlite;

class ShotwellSquareTagger {
    private const string DB_PATH = "~/.local/share/shotwell/data/photo.db";
    private Database db;
    private int tagged_count = 0;

    public static int main(string[] args) {
        var tagger = new ShotwellSquareTagger();
        
        try {
            tagger.run();
            return 0;
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
            return 1;
        }
    }
    
    private void run() throws Error {
        connect_to_db();
        tag_square_images();
        stdout.printf("Successfully tagged %d square images with 'square' tag.\n", tagged_count);
    }

    private void connect_to_db() throws Error {
        string expanded_path = DB_PATH.replace("~", Environment.get_home_dir());
        
        stdout.printf("Connecting to Shotwell database at %s\n", expanded_path);
        
        int rc = Database.open(expanded_path, out db);
        if (rc != Sqlite.OK) {
            throw new FileError.FAILED("Cannot open database: %s", db.errmsg());
        }
        
        stdout.printf("Successfully connected to database\n");
    }

    private void tag_square_images() throws Error {
        // Step 1: Get or create the 'square' tag
        int64 tag_id = get_or_create_tag("square");
        
        // Step 2: Find all images where height equals width
        stdout.printf("Finding square images...\n");
        
        Statement stmt;
        db.prepare_v2(
            "SELECT id, filename, width, height FROM PhotoTable WHERE width = height AND width > 0", 
            -1, 
            out stmt
        );
        
        // Step 3: Tag each square image
        while (stmt.step() == Sqlite.ROW) {
            int64 photo_id = stmt.column_int64(0);
            string filename = stmt.column_text(1);
            int width = stmt.column_int(2);
            int height = stmt.column_int(3);
            
            stdout.printf("Found square image: %s (%dx%d)\n", filename, width, height);
            
            // Tag the image if not already tagged
            if (!is_photo_tagged(photo_id, tag_id)) {
                tag_photo(photo_id, tag_id);
                tagged_count++;
            } else {
                stdout.printf("  Image already tagged as square\n");
            }
        }
    }
    
    private int64 get_or_create_tag(string tag_name) throws Error {
        int64 tag_id = -1;
        
        // Check if tag already exists
        Statement stmt;
        db.prepare_v2(
            "SELECT id FROM TagTable WHERE name = ?",
            -1,
            out stmt
        );
        
        stmt.bind_text(1, tag_name);
        
        if (stmt.step() == Sqlite.ROW) {
            tag_id = stmt.column_int64(0);
            stdout.printf("Found existing '%s' tag with ID: %" + int64.FORMAT + "\n", tag_name, tag_id);
        } else {
            // Create new tag
            Statement insert_stmt;
            db.prepare_v2(
                "INSERT INTO TagTable (name) VALUES (?)",
                -1,
                out insert_stmt
            );
            
            insert_stmt.bind_text(1, tag_name);
            insert_stmt.step();
            
            tag_id = db.last_insert_rowid();
            stdout.printf("Created new '%s' tag with ID: " + int64.FORMAT + "\n", tag_name, tag_id);
        }
        
        return tag_id;
    }
    
    private bool is_photo_tagged(int64 photo_id, int64 tag_id) throws Error {
        Statement stmt;
        db.prepare_v2(
            "SELECT photo_id FROM TagsTable WHERE photo_id = ? AND tag_id = ?",
            -1,
            out stmt
        );
        
        stmt.bind_int64(1, photo_id);
        stmt.bind_int64(2, tag_id);
        
        return stmt.step() == Sqlite.ROW;
    }
    
    private void tag_photo(int64 photo_id, int64 tag_id) throws Error {
        Statement stmt;
        db.prepare_v2(
            "INSERT INTO TagsTable (photo_id, tag_id) VALUES (?, ?)",
            -1,
            out stmt
        );
        
        stmt.bind_int64(1, photo_id);
        stmt.bind_int64(2, tag_id);
        stmt.step();
        
        stdout.printf("  Tagged photo ID %" + int64.FORMAT + " with 'square' tag\n", photo_id);
    }
}