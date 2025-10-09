export default async function handler(req, res) {
  try {
    const response = await fetch("https://raw.githubusercontent.com/janak0ff/zsh/main/setup_zsh.sh");
    const script = await response.text();
    res.setHeader("Content-Type", "text/plain");
    res.send(script);
  } catch (error) {
    res.status(500).send("Error fetching script");
  }
}
