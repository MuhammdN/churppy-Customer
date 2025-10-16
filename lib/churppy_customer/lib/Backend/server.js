const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const mysql = require("mysql2");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const app = express();
app.use(bodyParser.json());
app.use(cors());

// ✅ Secret key for JWT
const JWT_SECRET = "triloid_secret_key"; // production me ENV variable use karo

// ✅ Database connection
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "myapp"
});

db.connect(err => {
  if (err) {
    console.error("❌ Database connection failed:", err);
  } else {
    console.log("✅ Connected to MySQL");
  }
});

// ✅ Health check route
app.get("/", (req, res) => {
  res.send("API is running ✅");
});

// ✅ Signup Route (Customer side)
app.post("/signup", async (req, res) => {
  try {
    const {
      address,
      first_name,
      last_name,
      email,
      password,
      country_code,
      phone_number
    } = req.body;

    // Check required fields
    if (!address || !first_name || !last_name || !email || !password || !country_code || !phone_number) {
      return res.status(400).json({ status: "error", message: "All fields are required" });
    }

    // Check if email exists
    db.query("SELECT * FROM users WHERE email = ?", [email], async (err, results) => {
      if (err) return res.status(500).json({ status: "error", message: err.message });
      if (results.length > 0) {
        return res.status(400).json({ status: "error", message: "Email already exists" });
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      db.query(
        "INSERT INTO users (address, first_name, last_name, email, password, country_code, phone_number) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [address, first_name, last_name, email, hashedPassword, country_code, phone_number],
        (err) => {
          if (err) return res.status(500).json({ status: "error", message: err.message });

          res.json({ status: "success", message: "User registered successfully" });
        }
      );
    });
  } catch (error) {
    res.status(500).json({ status: "error", message: error.message });
  }
});

// ✅ Login Route
app.post("/login", (req, res) => {
  const { email, password } = req.body;

  db.query("SELECT * FROM users WHERE email = ?", [email], async (err, results) => {
    if (err) return res.status(500).json({ status: "error", message: err.message });
    if (results.length === 0) {
      return res.status(400).json({ status: "error", message: "Invalid email or password" });
    }

    const user = results[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ status: "error", message: "Invalid email or password" });
    }

    // ✅ Generate JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.json({
      status: "success",
      message: "Login successful",
      token,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        address: user.address,        // 👈 ab address return karega
        phone_number: user.phone_number,
        country_code: user.country_code
      }
    });
  });
});

// ✅ Protected Route Example
app.get("/profile", (req, res) => {
  const authHeader = req.headers["authorization"];
  if (!authHeader) return res.status(401).json({ status: "error", message: "No token provided" });

  const token = authHeader.split(" ")[1];
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) return res.status(403).json({ status: "error", message: "Invalid token" });

    res.json({
      status: "success",
      message: "Access granted to profile",
      user: decoded
    });
  });
});
// ✅ Businesses API
app.get("/businesses", (req, res) => {
  const query = `
    SELECT
      id,
      merchant_id AS merchantId,
      business_logo AS businessLogo,
      about_us AS aboutUs,
      cusine,
      opening_time AS openingTime,
      close_time AS closeTime
    FROM csdp_business_infos
  `;

  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ status: "error", message: err.message });
    }
    res.json({ status: "success", data: results });
  });
});


// ✅ Fetch Menu Items
app.get("/menu-items", (req, res) => {
  const query = `
    SELECT
      id,
      merchant_id AS merchantId,
      cat_id AS categoryId,
      title,
      image,
      description,
      fixed_price AS fixedPrice,
      multi_size AS multiSize,
      price,
      type_id AS typeId,
      instruction,
      instruction_image AS instructionImage,
      add_on AS addOn,
      add_on_image AS addOnImage,
      status,
      start_time AS startTime,
      end_time AS endTime,
      available_specific_time AS availableSpecificTime
    FROM csdp_menu_items
    WHERE deleted_at IS NULL
    ORDER BY created_at DESC
    LIMIT 50
  `;

  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ status: "error", message: err.message });
    }
    res.json({ status: "success", data: results });
  });
});
// GET /api/user/:id
app.get('/api/user/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const query = 'SELECT * FROM users WHERE id = ?';

    db.query(query, [userId], (error, results) => {
      if (error) {
        return res.status(500).json({ status: 'error', message: 'Database error' });
      }

      if (results.length === 0) {
        return res.status(404).json({ status: 'error', message: 'User not found' });
      }

      res.json({
        status: 'success',
        data: results[0]
      });
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});
// POST /api/user/:id/change-password
app.post('/api/user/:id/change-password', async (req, res) => {
  try {
    const userId = req.params.id;
    const { current_password, new_password } = req.body;

    // First verify current password
    const verifyQuery = 'SELECT password FROM users WHERE id = ?';

    db.query(verifyQuery, [userId], (error, results) => {
      if (error) {
        return res.status(500).json({ status: 'error', message: 'Database error' });
      }

      if (results.length === 0) {
        return res.status(404).json({ status: 'error', message: 'User not found' });
      }

      const storedPassword = results[0].password;

      // Compare current password (you should use bcrypt in production)
      if (current_password !== storedPassword) {
        return res.status(400).json({ status: 'error', message: 'Current password is incorrect' });
      }

      // Update password
      const updateQuery = 'UPDATE users SET password = ? WHERE id = ?';

      db.query(updateQuery, [new_password, userId], (error, results) => {
        if (error) {
          return res.status(500).json({ status: 'error', message: 'Database error' });
        }

        res.json({
          status: 'success',
          message: 'Password updated successfully'
        });
      });
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});
// PUT /api/user/:id
app.put('/api/user/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const { first_name, last_name, email, address, phone_number } = req.body;

    const query = `
      UPDATE users
      SET first_name = ?, last_name = ?, email = ?, address = ?, phone_number = ?
      WHERE id = ?
    `;

    db.query(query,
      [first_name, last_name, email, address, phone_number, userId],
      (error, results) => {
        if (error) {
          return res.status(500).json({ status: 'error', message: 'Database error' });
        }

        res.json({
          status: 'success',
          message: 'User updated successfully'
        });
      }
    );
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});
// ✅ Fetch Active Alerts
app.get("/alerts", (req, res) => {
  db.query(
    "SELECT id, title, description, image, location, city, state, start_date, expiry_date FROM csdp_merchant_alerts WHERE status = 1 ORDER BY created_at DESC LIMIT 20",
    (err, results) => {
      if (err) {
        return res.status(500).json({ status: "error", message: err.message });
      }
      res.json({ status: "success", data: results });
    }
  );
});

// ✅ Start server (0.0.0.0 so physical device can connect)
app.listen(5000, "0.0.0.0", () => {
  console.log("🚀 Server running on http://0.0.0.0:5000");
});
