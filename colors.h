#ifndef COLORS_H_
#define COLORS_H_

#define COLOR_STD	            "\033[39m"
#define COLOR_WHITE	            "\033[97m"
#define COLOR_LIGHT_GRAY	    "\033[37m"
#define COLOR_DARK_GRAY	        "\033[90m"
#define COLOR_BLACK	            "\033[30m"
#define COLOR_RED	            "\033[31m"
#define COLOR_YELLOW	        "\033[33m"
#define COLOR_GREEN	            "\033[32m"
#define COLOR_BLUE	            "\033[34m"
#define COLOR_MAGENTA	        "\033[35m"
#define COLOR_CYAN	            "\033[36m"
#define COLOR_LIGHT_RED	        "\033[91m"
#define COLOR_LIGHT_YELLOW	    "\033[93m"
#define COLOR_LIGHT_GREEN	    "\033[92m"
#define COLOR_LIGHT_BLUE	    "\033[94m"
#define COLOR_LIGHT_MAGENTA	    "\033[95m"
#define COLOR_LIGHT_CYAN	    "\033[96m"

#define	BG_STD                  "\033[49m"
#define	BG_BLACK                "\033[40m"
#define	BG_RED                  "\033[41m"
#define	BG_GREEN                "\033[42m"
#define	BG_YELLOW               "\033[43m"
#define	BG_BLUE                 "\033[44m"
#define	BG_MAGENTA              "\033[45m"
#define	BG_CYAN                 "\033[46m"
#define	BG_LIGHT_GRAY           "\033[47m"
#define	BG_DARK_GRAY            "\033[100m"
#define	BG_LIGHT_RED            "\033[101m"
#define	BG_LIGHT_GREEN          "\033[102m"
#define	BG_LIGHT_YELLOW         "\033[103m"
#define	BG_LIGHT_BLUE           "\033[104m"
#define	BG_LIGHT_MAGENTA        "\033[105m"
#define	BG_LIGHT_CYAN           "\033[106m"
#define	BG_WHITE                "\033[107m"


#define FONT_BOLD               "\033[1m"
#define FONT_ITALIC             "\033[3m"
#define FONT_UNDERLINED         "\033[4m"
#define FONT_BLINK              "\033[5m"
#define FONT_REVERSE            "\033[7m"
#define FONT_HIDDEN             "\033[8m"

#define TEXT_SETTINGS_RESET     "\033[0m"

#define PAINT_TEXT(COLOR, TEXT) COLOR TEXT COLOR_STD


#endif
