const express = require("express");
const path = require("path");
const router = express.Router();

/* GET home page. */
router.get("/", function(req, res, next) {
  res.send({msg: "Hello"}).status(200);
});

router.get("/health", async (req, res) => {
  res.render('index', {
    haproxy_public_ip: process.env.HAPROXY_PUBLIC_IP
  });
});

module.exports = router;
