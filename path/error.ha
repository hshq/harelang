// Returned when adding an extension if the path is root, or the final path
// segment consists entirely of dots.
export type cant_extend = !void;
// Returned when a path buffer would have overflowed.
export type too_long = !void;
export type error = !(cant_extend | too_long);

// Convert an [[error]] into a descriptive string.
export fn strerror(e: error) str = match (e) {
case cant_extend => return "Can't add extension (filename is root or all dots)";
case too_long => return "Path buffer overflow";
};
