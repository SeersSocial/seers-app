const tailwindcss = require("tailwindcss")
const autoprefixer = require("autoprefixer")

const config = {
  plugins: [
    //Some plugins, like tailwindcss/nesting, need to run before Tailwind,
    //But others, like autoprefixer, need to run after,
    tailwindcss(),
    autoprefixer,
    autoprefixer,
    autoprefixer,
  ],
}

module.exports = config
