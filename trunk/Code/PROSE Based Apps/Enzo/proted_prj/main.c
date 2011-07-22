/*
	PROTED: PROse Text eDitor
	
	coded by Calogiuri Enzo Antonio for PROSE community.	
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>

#include "PROSE_Header.h"

#define TEBUFMAX		2048					/* Bytes in the terminal package output buffer.        */
#define MAXLNLEN		80						/* Maximum line length this editor can handle.         */
#define SCNROWS			50						/* Number of rows    in target terminal.               */
#define SCNCOLS			80						/* Number of columns in target terminal.               */
#define VERSION			"1.1"					/* Version number of this editor.                      */
#define FUDGE			10
#define FALSE			0
#define TRUE			1
#define SCNSIZE 		(SCNROWS * SCNCOLS)

#define EOS 			'\0'
#define EOL 			'\n'
#define CH_TAB 			9

int tebuflen;
static char tebuf[TEBUFMAX + FUDGE];
char scn_virt[SCNROWS][SCNCOLS];
char scn_phys[SCNROWS][SCNCOLS];
char backbuffer[4][SCNCOLS];

typedef struct line_t_ line_t;
#define p_line_t line_t *
struct line_t_
 {
   p_line_t 	p_prev;						/* Pointer to the previous line record.                  */
   p_line_t 	p_next;						/* Pointer to the next     line record.                  */
   char   		*p_data; 					/* Pointer to the line itself (C string in heap).        */
 };
 
line_t root;								/* The root line (unused as a line).               */
p_line_t p_root;							/* Pointer to the root line.                       */
p_line_t p_curr;							/* Ptr to the current line (or root if at EOF).    */
int numlines, cur_line, cur_char, cur_row, cur_col;
char linbuf[MAXLNLEN+FUDGE]; 

static unsigned char Ascii, Scancode, B, C, E, InsertMode;
unsigned int K_xHL, K_xBC, filesize;
char *BufferFile = (char *)0x0C00000;		/* Use VGA Ram B to load or save file      */
static char *TxtPnt;
static char *NonameFile = "noname.txt";
char UseFile;

void GetCh(void);
unsigned char getch(void);
void print(const char *Txt);
void get_cursor_position(unsigned char *X, unsigned char *Y);
void plot_char(unsigned char x, unsigned char y, unsigned char Ch);
void clreol(void);
void gotoxy(unsigned char x, unsigned char y);
int get_prose_version(void);
void get_display_size(void);

void uitoa(unsigned int val, char *string);
char convBuf[5];

void ShowMenu(void);
void ShowInsertMode(void);
void Enable_Back_Color(void);
void Disable_Back_Color(void);
void Show_Cursor(void);
void Show_Cursor_Position(void);

char FileExists(void);
void load_file(void);
void save_file(void);
void reload_file(void);

void msg_window(char *msg1, char *msg2);
void close_msg_window(void);

/*-------------------------------------------------------------------------*/

void bomb(char *txt);
void as(char b, char *txt);
void *mymalloc(size_t n);
char blankrow(char *p);
void zap_trail(char *s);
void purify(char *st);
void te_flu(void);
unsigned char te_gch(void);
void te_chr(char ch);
void te_str(char *s);
void te_mov(unsigned char r, unsigned char c);
void te_cln(unsigned char row);
void te_clr(void);
void te_ini(void);
void te_fin(void);

void sc_clr(void);
void sc_crw(unsigned char row);
void sc_chr(unsigned char row, unsigned char col, unsigned char ch);
void sc_str(unsigned char row, unsigned char col, char *s);
void sc_upd(void);
void sc_fup(void);
void sc_ini(void);
void sc_fin(void);

void tx_ini(void);
void tx_set(p_line_t p_line, char *s);
void tx_ins(p_line_t p_line, char *s);
void tx_del(p_line_t p_line);
void tx_get(p_line_t p_line);
void tx_put(p_line_t p_line);

void do_red(void);
void do_cup(void);
void do_cdw(void);
void do_clf(void);
void do_crt(void);
void do_pdw(void);
void do_pup(void);
void do_ret(void);
void do_enhanced_ret(void);
void do_tab(void);
void do_top(void);
void do_bot(char paint);
void do_chr(char ch);
void do_dch(void);
void do_iln(void);
void do_dln(void);
void do_del(void);
void do_enhanced_del(void);
void do_home(void);
void do_endline(void);
void do_ins(void);

void paintall(void);
void paintrow(void);

void edit(void);

/*-------------------------------------------------------------------------*/
void main(void)
{
	INIT_HARDWARE;
	INIT_KJT;
	
	CREATE_HEADER;
	
	UseFile = 0;	
	
	asm ("ld a, (hl)");
	asm ("or a");
	asm ("jr z, no_param");
	asm ("ld (_K_xHL), hl");	//If parameter passed, save the position in K_xHL
	
	UseFile = 1;
	
	asm ("no_param:");
	
	if (get_prose_version() < 0x2F)
	{
		print("Proted require PROSE ver 2F or later!\n\r");
		
		QUIT_TO_PROSE;
		
		return;
	}
	
	get_display_size();
	
	if (!((B == 80) && (C == 60)))
	{
		print("Proted require 80x60 characters mode (VMODE 0)!\n\r");
		
		QUIT_TO_PROSE;
		
		return;
	}
	
	asm ("push ix");
	asm ("ld a, kr_clear_screen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	memset(BufferFile, 0, 1024 * 512);	
	
	ShowMenu();
	
	te_ini();
	sc_ini();
	tx_ini();
	
	if (UseFile == 1)
		if (FileExists() == 1)
			load_file();		
	
	edit();
	
	sc_fin();
	te_fin();
	
	asm ("proted_exit:");
	asm ("push ix");
	asm ("ld a, kr_clear_screen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	print("\n\r");
	print("PROTED ver ");
	print(VERSION);
	print(" rel.: ");
	print(__DATE__);
	print("\n\r");
	print("Created by Calogiuri Enzo Antonio for eZ80P fans :-)\n\r");	
	
	QUIT_TO_PROSE;
}

/* Get ascii and scancode value of key pressed */
void GetCh(void)
{
	Ascii = Scancode = 0;
	
	asm ("push ix");
	asm ("ld a, kr_get_key");
	asm ("call.lil prose_kernal");
	asm ("jr nz, NoKeyInB");
	asm ("ld (_Scancode), a");
	asm ("ld a, b");
	asm ("ld (_Ascii), a");
	asm ("NoKeyInB:");
	asm ("pop ix");
}

/* Manage the input from keyboard */
unsigned char getch(void)
{
	while (1)
	{	
		GetCh();	
		
		switch (Scancode)
		{
			case 0x7D	: Ascii = 3; break;
			
			case 0x71	: Ascii = 4; break;	

			case 0x7A	: Ascii = 6; break;
			
			case 102	: Ascii = 8; break;
			
			case 0xD	: Ascii = 9; break;			
			
			case 90		: Ascii = 13; break;			
			
			case 0x12	: while (Ascii == 0)
							GetCh();
							
						  break;
			
			case 0x6B	:
			case 0x75	:
			case 0x72	:
			case 0x6C	:
			case 0x69	:
			case 0x70	:
			case 0x74	: Ascii = 1; break;
		}
		
		if (Ascii != 0)
			break;		
	}	
		
	return Ascii;
}

/* Print on screen a text at current x,y position */
void print(const char *Txt)
{
	TxtPnt = Txt;
	
	asm ("push ix");
	asm ("ld hl, (_TxtPnt)");
	asm ("ld a, kr_print_string");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

/* Get the x and the y of screen cursor */
void get_cursor_position(unsigned char *X, unsigned char *Y)
{
	asm ("push ix");
	asm ("ld a, kr_get_cursor_position");
	asm ("call.lil prose_kernal");
	asm ("ld a, b");
	asm ("ld (_B), a");
	asm ("ld a, c");
	asm ("ld (_C), a");
	asm ("pop ix");
	
	*X = B;
	*Y = C;
}

/* Draw a character at X, Y coordinates */
void plot_char(unsigned char x, unsigned char y, unsigned char Ch)
{
	B = x;
	C = y;
	E = Ch;
	
	asm ("push ix");
	asm ("ld hl, _B");
	asm ("ld B, (hl)");
	asm ("ld hl, _C");
	asm ("ld C, (hl)");
	asm ("ld hl, _E");
	asm ("ld E, (hl)");
	asm ("ld a, kr_plot_char");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

/* Clear the row on screen from current x,y position */
void clreol(void)
{
	unsigned char x, y;
	register char i;
	
	get_cursor_position(&x, &y);
	
	for (i = x; i < 80; i++)
		plot_char(i, y, ' ');		
}

/* Move screen cursor at x,y position */
void gotoxy(unsigned char x, unsigned char y)
{
	B = x;
	C = y;
	
	asm ("push ix");
	asm ("ld hl, _B");
	asm ("ld B, (hl)");
	asm ("ld hl, _C");
	asm ("ld C, (hl)");
	asm ("ld a, kr_set_cursor_position");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

/* Return only PROSE version */
int get_prose_version(void)
{
	asm ("push ix");
	asm ("push de");
	asm ("push hl");
	asm ("ld a, kr_get_version");
	asm ("call.lil prose_kernal");
	asm ("ld (_K_xBC), hl");
	asm ("pop hl");
	asm ("pop de");
	asm ("pop ix");
	
	return K_xBC;
}

/* Return PROSE screen dimension stored in B = Width, C = Height */
void get_display_size(void)
{
	asm ("push ix");
	asm ("ld a, kr_get_display_size");
	asm ("call.lil prose_kernal");
	asm ("ld a, b");
	asm ("ld (_B), a");
	asm ("ld a, c");
	asm ("ld (_C), a");
	asm ("pop ix");
}

/*-------------------------------------------------------------------------*/

/* Writes out its argument string and then halt the program. */
void bomb(char *txt)
{
	msg_window("Proted assertion failure. Press RETURN to abort!", txt);
	
	while (1)
	{
		getch();
		
		if (Ascii == 13)
			break;
	}

	asm ("ld a, 0ffh");
	asm ("jp.lil prose_return");
}

/* Bombs with an assertion failure if its first argument is FALSE. */
void as(char b, char *txt)
{
	if (!b)
		bomb(txt);
}

/* Convert an unsigned int into string */
void uitoa(unsigned int val, char *string)
{
	char index = 0, i = 0;
	
	do {
		string[index] = '0' + (val % 10);
		
		if (string[index] > '9')
			string[index] += 'A' - '9' - 1;
		
		val /= 10;
		++index;
  } while (val != 0);
  
  string[index--] = '\0'; 
  
  while (index > i)
  {
    char tmp = string[i];
	  
    string[i] = string[index];
    string[index] = tmp;
    ++i;
    --index;
  }
}

/* The same as malloc except it bombs if it cannot perform the allocation. */
void *mymalloc(size_t n)
{
	void *p;
	
	if (n == 0)
		n++;
	
	p = malloc(n);
	
	as(p != NULL, "out of memory!");
	
	return p;
}

/* Returns TRUE if p[0..SCNCOLS - 1] are all blanks. */
char blankrow(char *p)
{
	register unsigned char i;
	
	for (i = 0; i < SCNCOLS; i++)
		if (p[i] != ' ')
			return FALSE;
		
	return TRUE;
}

/* Deletes trailing blanks from its argument string. */
void zap_trail(char *s)
{
	char *p = s;
	
	while (*s != EOS)
	{
		if (*s != ' ')
			p = s + 1;
		
		s++;
	}
	
	*p = EOS;
}

/* Deletes all non-printables from the argument string. */
/* Replaces each TAB by a space.                        */
void purify(char *st)
{
	char *s = st;
	char *d = st;
	
	while (*s)
	{
		if ((' ' <= *s) && (*s <= '~'))
			*d++ = *s;
		
		if (*s == CH_TAB)		
			*d++ = ' ';
		
		s++;
	}
	
	*d = EOS;
}

/* Flushes the terminal's output buffer tebuf to screen. */
void te_flu(void)
{
	if (tebuflen == 0)
		return;
	
	tebuf[tebuflen] = EOS;
	
	print(tebuf);
	
	tebuflen = 0;
}

/* Get a character from the console. */
unsigned char te_gch(void)
{
	te_flu();
	
	return getch();
}

/* Writes its argument character to the terminal. */
void te_chr(char ch)
{
	tebuf[tebuflen++] = (char) ch;
	
	if (tebuflen == TEBUFMAX)
		te_flu();
}

/* Writes its argument string to the terminal. */
void te_str(char *s)
{
	while (*s)
		te_chr((unsigned char)(*s++));
}

/* Moves the cursor to the specified row and column on the screen. */
void te_mov(unsigned char r, unsigned char c)
{
	as((0 <= r) && (r <= SCNROWS), "te_mov: Bad row.");	//Mod
	
	as((0 <= c) && (c <= SCNCOLS), "te_mov: Bad col.");	//Mod
	
	te_flu();
	
	gotoxy(c, r);
}

/* Sets the specified row of the terminal to blanks.   */
/* Leaves the cursor at the start of the cleared line. */
void te_cln(unsigned char row)
{
	te_mov(row, 0);
	
	clreol();
}

/* Homes the cursor and clears the screen. */
void te_clr(void)
{
	register unsigned char r;
	
	for (r = 0; r < SCNROWS; r++)
		te_cln(r);
	
	te_mov(0, 0);
}

/* Initializes the terminal package. */
void te_ini(void)
{
	tebuflen = 0;
}

/* Finalize the terminal package. */
void te_fin(void)
{
	te_flu();
}

/* Clear the virtual screen. */
void sc_clr(void)
{
	memset(&scn_virt[0][0], ' ', SCNSIZE);
}

/* Clear the specified row of the virtual screen. */
void sc_crw(unsigned char row)
{
	as((0 <= row) && (row <= SCNROWS), "sc_crw: Bad row number.");
	
	memset(&scn_virt[row][0], ' ', SCNCOLS);
}

/* Places the specified character at the specified row and column on the      */
/* screen. If the row and column are off screen, it simply does nothing.      */
void sc_chr(unsigned char row, unsigned char col, unsigned char ch)
{
	if (((0 <= row) && (row < SCNROWS)) && ((0 <= col) && (col < SCNCOLS)))
		scn_virt[row - 0][col - 0] = (char) ch;
}

/* Writes the specified string on the virtual screen at the specified row and column. */
/* The function ignores any part of the string that falls off the screen.     		  */
void sc_str(unsigned char row, unsigned char col, char *s)
{
	unsigned char c = col;
	char *t = s;
	
	while (*t)
		sc_chr(row, c++, (unsigned char)(*t++));
}

/* Updates the physical screen from the virtual screen by:                    */
/* - Identifying the differences between the physical and virtual screens.    */
/* - Sending characters to the terminal package to implement the changes.     */
/* - Setting the physical screen to the virtual screen.                       */
void sc_upd(void)
{
	register unsigned char r, c;
	
	for (r = 0; r < SCNROWS; r++)
	{
		if (memcmp(&scn_virt[r - 0][0], &scn_phys[r - 0][0], SCNCOLS) == 0)
			continue;
		
		if ((blankrow(&scn_virt[r - 0][0])) && (!blankrow(&scn_phys[r - 0][0])))
			te_cln(r);
		else
		{
			char there = FALSE;
			
			for (c = 0; c < SCNCOLS; c++)
			{
				char ch = scn_virt[r - 0][c - 0];
				
				if (ch != scn_phys[r - 0][c - 0])
				{
					if (!there)
						te_mov(r, c);
					
					te_chr((unsigned char)(ch));
					
					there = TRUE;
				}
				else
					there = FALSE;
			}
		}
		
		memmove(&scn_phys[r - 0][0], &scn_virt[r - 0][0], SCNCOLS);
	}	
	
	te_flu();	
}

/* Forced update. Forces the terminals screen to be redrawn from scratch from */
/* the virtual screen.                                                        */
void sc_fup(void)
{
	memset(&scn_phys[0][0], 0, SCNSIZE);
	
	sc_upd();
}

/* Initializes the screen package, clearing the screen. */
void sc_ini(void)
{
	sc_clr();
	
	sc_fup();
}

/* Finalizes the screen package, clearing the screen. */
void sc_fin(void)
{
	sc_clr();
	
	sc_fup();
}

/* Initialize the text data structure to the empty list. */
void tx_ini(void)
{
	p_root = &root;
	p_root->p_next = p_root;
	p_root->p_prev = p_root;
	p_root->p_data = NULL;
	
	numlines = 0;
}

/* Sets the specified line to the specified string value. */
/* Deletes trailing spaces from the argument string first. */
void tx_set(p_line_t p_line, char *s)
{
	size_t len;
	
	zap_trail(s);
	
	len = strlen(s);
	
	as(len <= MAXLNLEN, "tx_set: Line too long.");	
	as(p_line != p_root, "tx_set: Attempt to set the root line.");
	as(p_line->p_data != NULL, "tx_set: p_data=NULL.");
	
	free(p_line->p_data);
	
	p_line->p_data = mymalloc(len + 1);
	
	strcpy(p_line->p_data, s);
}

/* Insert a line containing the specified string */
/* just before the specified line.               */
void tx_ins(p_line_t p_line, char *s)
{
	p_line_t p_new = mymalloc(sizeof(line_t));
	
	p_new->p_prev = p_line->p_prev;
	p_new->p_next = p_line;
	
	p_line->p_prev = p_new;
	p_new->p_prev->p_next = p_new;
	
	p_new->p_data = mymalloc(0);
	
	tx_set(p_new, s);
	
	numlines++;
}

/* Deletes the specified line. */
void tx_del(p_line_t p_line)
{
	as(p_line != NULL, "tx_del: NULL.");
	as(p_line != p_root, "tx_del: Attempt to delete the root line.");
	
	p_line->p_prev->p_next = p_line->p_next;
	p_line->p_next->p_prev = p_line->p_prev;
	
	free(p_line->p_data);
	free(p_line);
	
	numlines--;
}

/* Writes the contents of the line to the global line buffer as a blank       */
/* padded array of MAXLNLEN characters.                                       */
void tx_get(p_line_t p_line)
{
	size_t len = strlen(p_line->p_data);
	
	memset((void *)linbuf, ' ', MAXLNLEN);
	
	memmove((void *)linbuf, p_line->p_data, len);
}

/* Sets the value of the specified line to the value of the global linebuffer.*/
void tx_put(p_line_t p_line)
{
	linbuf[MAXLNLEN] = EOS;
	
	tx_set(p_line, linbuf);
}

/* Redraw the screen. */
void do_red(void)
{
	sc_fup();
}

/* Cursor up. */
void do_cup(void)
{
	char ch;
	
	if (cur_line == 1)
	{
		Show_Cursor();
		
		return;
	}
	
	cur_line--;
	
	p_curr = p_curr->p_prev;
	
	if (cur_row == 0)
		paintall();
	else
	{
		ch = scn_phys[cur_row][cur_col];
		
		cur_row--;
		
		plot_char(cur_col, cur_row + 1, ch);
	}
}

/* Cursor down. */
void do_cdw(void)
{
	char ch;
	
	if (p_curr->p_next == p_root)
	{
		Show_Cursor();
		
		return;
	}
	
	p_curr = p_curr->p_next;
	
	cur_line++;
	
	if (cur_row == SCNROWS - 1)
		paintall();	
	else
	{
		ch = scn_phys[cur_row][cur_col];
		
		cur_row++;
		
		plot_char(cur_col, cur_row - 1, ch);		
	}
}

/* Cursor left. */
void do_clf(void)
{
	char ch;
	
	if (cur_char == 1)
	{
		Show_Cursor();
		
		return;
	}
	
	cur_char--;
	
	if (cur_col == 0)
		paintall();
	else
	{
		ch = scn_phys[cur_row][cur_col];
		
		cur_col--;
		
		plot_char(cur_col + 1, cur_row, ch);
	}
}

/* Cursor right. */
void do_crt(void)
{
	char ch;
	
	if (cur_char == MAXLNLEN)
	{
		Show_Cursor();
		
		return;
	}
	
	cur_char++;
	
	if (cur_col == SCNCOLS - 1)
		paintall();
	else
	{
		ch = scn_phys[cur_row][cur_col];
		
		cur_col++;
		
		plot_char(cur_col - 1, cur_row, ch);
	}
}

/* Page down. */
void do_pdw(void)
{
	register char i;
	char ch, oldr = cur_row;
	
	for (i = 0; i < SCNROWS; i++)
	{
		if (cur_line == numlines + 1)
			break;
		
		p_curr = p_curr->p_next;
		
		cur_line++;
		cur_row++;
	}
	
	if (cur_row > SCNROWS - 1)
		cur_row = SCNROWS - 1;
	
	paintall();
	
	ch = scn_phys[oldr][cur_col];
	
	plot_char(cur_col, oldr, ch);
	
	Show_Cursor();
}

/* Page up. */
void do_pup(void)
{
	register char i;
	char ch, oldr = cur_row;
	
	for (i = 0; i < SCNROWS; i++)
	{
		if (cur_line == 1)
			break;
		
		p_curr = p_curr->p_prev;
		
		cur_line--;
		cur_row--;
	}
	
	if (cur_row < 0)
		cur_row = 0;	
	
	paintall();
	
	ch = scn_phys[oldr][cur_col];
	
	plot_char(cur_col, oldr, ch);
	
	Show_Cursor();
}

/* Return. */
void do_ret(void)
{
	char len = strlen(p_curr->p_data);
	char ch, oldr = cur_row, oldc = cur_col;
	
	gotoxy(len, cur_row);
	
	clreol();
	
	ch = scn_phys[oldr][oldc];
	
	plot_char(oldc, oldr, ch);
	
	cur_char = 1;
	cur_col  = 0;
	
	ch = scn_phys[oldr][oldc];
	
	plot_char(oldc, oldr, ch);
	
	do_cdw();
}

/* Enhanced Return. Break a line into two lines */
void do_enhanced_ret(void)
{
	char len = strlen(p_curr->p_data);
	char app[MAXLNLEN], app2[MAXLNLEN];
	
	if (cur_col < len)
	{
		memset(app, 0, MAXLNLEN);
		memset(app2, 0, MAXLNLEN);
		
		memmove(app, p_curr->p_data + cur_col, len - cur_col);
		
		memmove(app2, p_curr->p_data, cur_col);
		
		do_iln();
		
		tx_set(p_curr, app);
		
		tx_set(p_curr->p_prev, app2);
		
		paintall();
		
		do_cup();
	}
	
	do_ret();
}

/* Tab. */
void do_tab(void)
{
	int x = cur_char;
	
	do
	{
		do_crt();
		x++;
	} while (((x - 1) % 8) != 0);
}

/* Jump to top of document. */
void do_top(void)
{
	char oldr, oldc;
	
	oldr = cur_row;
	oldc = cur_col;
	
	p_curr = p_root->p_next;
	
	cur_line = 1;
	cur_char = 1;
	cur_row = 0;
	cur_col = 0;
	
	paintall();
	
	plot_char(oldc, oldr, scn_phys[oldr][oldc]);
}

/* Jump to bottom of document. */
void do_bot(char paint)
{
	char oldr, oldc;
	
	oldr = cur_row;
	oldc = cur_col;
	
	p_curr = p_root;
	
	cur_line = numlines + 1;
	cur_row = numlines;
	cur_char = 1;
	cur_col = 0;
	
	if (cur_row > SCNROWS - 1)
		cur_row = SCNROWS - 1;
	
	if (paint)
		paintall();
	
	plot_char(oldc, oldr, scn_phys[oldr][oldc]);
}

/* Type the specified character. */
void do_chr(char ch)
{
	register int i;
	
	if (p_curr == p_root)
		return;

	if (cur_char == MAXLNLEN + 1)
	{
		Show_Cursor();
		
		return;
	}
	
	tx_get(p_curr);	
	
	if (InsertMode != 0)
	{
		for (i = MAXLNLEN - 1; i > cur_char - 1; i--)
			linbuf[i] = linbuf[i - 1];
	}	
	
	linbuf[cur_char - 1] = (char)(ch);
	
	tx_put(p_curr);
	
	do_crt();
	paintrow();
}

/* Delete character. */
void do_dch(void)
{
	register int i;
	
	if (p_curr == p_root)
		return;
	
	tx_get(p_curr);
	
	for (i = cur_char - 1; i < MAXLNLEN - 1; i++)
		linbuf[i] = linbuf[i + 1];
	
	linbuf[MAXLNLEN - 1] = ' ';
	
	tx_put(p_curr);
	
	paintrow();
}

/* Insert line. */
void do_iln(void)
{
	paintrow();
	
	if (cur_line < numlines)
	{
		do_cdw();
		
		tx_ins(p_curr, "");
		
		p_curr = p_curr->p_prev;
	}		
	else
	{
		tx_ins(p_root, "");		
		
		do_bot(0);
	}
	
	cur_char = 1;
	cur_col = 0;
	
	paintall();	
}

/* Delete line. */
void do_dln(void)
{
	p_line_t save = p_curr->p_next;
	
	if (p_curr == p_root)
		return;
	
	tx_del(p_curr);
	
	p_curr = save;
	
	paintall();
}

/* Delete. */
void do_del(void)
{
	if (cur_char == 1)
		if (strlen(p_curr->p_data) <= 0)
			return;
		else
		{
			do_enhanced_del();
			
			return;
		}
	
	do_clf();
	
	do_dch();
}

/* Enhanced Delete. Can join current line with previous line. */
void do_enhanced_del(void)
{
	char app[MAXLNLEN], i, oldPos;
	
	if (cur_line == 1)
	{
		Show_Cursor();
		
		return;		
	}
	
	memset(app, 0, MAXLNLEN);	
	
	memmove(app, p_curr->p_data, strlen(p_curr->p_data));
	
	do_dln();	
	
	do_cup();
	do_endline();
	
	oldPos = cur_col;
	
	for (i = 0; i < strlen(app); i++)
		do_chr(app[i]);	
	
	paintrow();
	
	cur_col = oldPos;
	cur_char = cur_col + 1;
}

/* Go to the start of current line. */
void do_home(void)
{
	char ch, oldcol;
	
	if (p_curr == p_root)
		return;
	
	ch = scn_phys[cur_row][cur_col];
	oldcol = cur_col;
	
	cur_char = 1;
	cur_col = 0;
	
	plot_char(oldcol, cur_row, ch);
}

/* Go to the end of current line. */
void do_endline(void)
{
	char len, ch, oldcol;
	
	if (p_curr == p_root)
		return;
	
	len = strlen(p_curr->p_data);	
	
	ch = scn_phys[cur_row][cur_col];
	oldcol = cur_col;
	
	cur_col = len;
	cur_char = len + 1;
	
	plot_char(oldcol, cur_row, ch);
}

/* Set insert or overwrite mode */
void do_ins(void)
{
	if (InsertMode != 0)
		InsertMode = 0;
	else
		InsertMode = 1;
	
	ShowInsertMode();
	
	gotoxy(cur_col, cur_row);
	
	Show_Cursor();
}

/* Redraws the virtual screen from scratch from the current settings. */
void paintall(void)
{
	register unsigned char r;
	p_line_t p = p_curr;
	int left_pos = cur_char - cur_col;
	unsigned char len;
	
	for (r = 0; r < cur_row; r++)
		p = p->p_prev;
	
	sc_clr();
	
	for (r = 0; r < SCNROWS; r++)
	{
		if (p == p_root)
		{
			sc_str(r, 0, "<eof>");
			
			do_cup();
			
			break;
		}
		
		len = strlen(p->p_data);
		
		if (len >= left_pos)
			sc_str(r, 0, p->p_data + (left_pos - 1));
		else
			if (len == 0)
				plot_char(0, r, ' ');
		
		p = p->p_next;
	}
	
	te_mov(cur_row, cur_col);

	Show_Cursor();
}

/* Redraws the current row of the virtual screen */
/* from scratch from the current settings.       */
void paintrow(void)
{
	unsigned char left_pos = cur_char - cur_col;
	char len;
	
	len = strlen(p_curr->p_data);
	
	sc_crw(cur_row);
	
	if (p_curr == p_root)
		sc_str(cur_row, 0, "<eof>");
	else
		if (len >= left_pos)
		{
			sc_str(cur_row, 0, p_curr->p_data + (left_pos - 1));			
	
			gotoxy(len, cur_row);
			
			clreol();
		}
}

/* Show curson on screen. */
void Show_Cursor(void)
{
	asm ("push ix");
	asm ("ld a, kr_draw_cursor");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
}

/* Show PROTED menù */
void ShowMenu(void)
{
	Enable_Back_Color();
	
	gotoxy(0, 50);	
	print("+==================================]PROTED[====================================+");
	print("| Ln:       , Col:                                                             |");
	print("|                                                                              |");
	print("| Command  shortcuts:                                                          |");
	print("| Ctrl + L: insert a line.   Ctrl + E: end of text.   Ctrl + K: delete a line. |");
	print("| Ctrl + N: redraw screen.   Ctrl + T: top of file.   Ctrl + S: save file.     |");
	print("| Ctrl + B: break a line.    Ctrl + R: reload file.   Ctrl + Q: quit to PROSE. |");
	print("|      Key enabled: Tab, Cursor Keys, PgUp, PgDown, Home, End, Del, Ins.       |");
	print("+==============================================================================+");
	
	Disable_Back_Color();
}

/* Show Type Mode */
void ShowInsertMode(void)
{
	Enable_Back_Color();
	
	gotoxy(54, 51);	
	print("                     ");
	
	gotoxy(54, 51);
	print("Type mode: ");
	
	if (InsertMode)
		print("Insert");
	else
		print("Overwrite");
	
	Disable_Back_Color();
}

/* Enable the background color for print string */
void Enable_Back_Color(void)
{
	asm ("push ix");
	asm ("ld E, E7h");
	asm ("ld a, kr_set_pen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

/* Disable the background color for print string */
void Disable_Back_Color(void)
{
	asm ("push ix");
	asm ("ld E, 07h");
	asm ("ld a, kr_set_pen");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
}

/* Main edit loop */
void edit(void)
{
	cur_row = 0;
	cur_col = 0;
	cur_line = 1;
	cur_char = 1;
	InsertMode = 1;
	p_curr = p_root->p_next;	
	
	paintall();
	
	sc_fup();
	
	ShowInsertMode();
	
	while (TRUE)
	{
		char ch;
		
		sc_upd();
		
		Show_Cursor_Position();
		
		te_mov(cur_row, cur_col);

		Show_Cursor();		
		
		ch = te_gch();
		
		if ((' ' <= ch) && (ch <= '~'))
			do_chr(ch);
		else
			switch (ch)
			{
				case		2: do_enhanced_ret(); break;		/* Control-B. Break Line.             */
				case		3: do_pup(); break;					/* PageUp.             				  */
				case		4: do_dch(); break;					/* Delete character, Canc Key.		  */
				case		5: do_bot(1); break;				/* Control-E. End of text.      	  */
				case 		6: do_pdw(); break;					/* PageDown.           				  */
				case 		8: do_del(); break;					/* Delete character, Backspace Key.	  */
				case		9: do_tab(); break;					/* Tab.           				  	  */
				case		11: do_dln(); break;				/* Control-K. Delete line.      	  */
				case		12: do_iln(); break;				/* Control-L. Insert line.      	  */
				case 		13: do_ret(); break;				/* Return (No new line)				  */
				case		14: do_red(); break;				/* Control-N. Redraw screen.    	  */
				case		18: reload_file(); break;			/* Control-R. Reload file.	     	  */
				case		19: save_file(); break;				/* Control-S. Save file.	     	  */
				case		20: do_top(); break;				/* Control-T. Top of file.      	  */
				
				case		17: msg_window("Quit to PROSE ?", "Y/n");	/* Control-Q. Exit.      	  */
								getch();
								close_msg_window();
								
								if ((Ascii != 89) && (Ascii != 121))
								 continue;
								
								goto quit;
					
				case		1:
					switch (Scancode)
					{
						case	0x74: do_crt(); break;			/* Cursor right.					  */
						case	0x6B: do_clf(); break;			/* Cursor left.					  	  */
						case	0x75: do_cup(); break;			/* Cursor up.					  	  */
						case	0x72: do_cdw(); break;			/* Cursor down.					  	  */
						case	0x6C: do_home(); break;			/* Home key.					  	  */
						case	0x69: do_endline(); break;		/* End key.					  	  	  */
						case	0x70: do_ins(); break;			/* Ins key.           				  */
					}
					break;
			}
	}
	
	quit:;
}

/* Draw on screen the cursor position */
void Show_Cursor_Position(void)
{
	Enable_Back_Color();
	
	uitoa(cur_line, convBuf);
	
	gotoxy(5, 51);
	
	print("      ");
	
	gotoxy(5, 51);
	
	print(convBuf);	
	
	uitoa(cur_col + 1, convBuf);
	
	gotoxy(18, 51);
	
	print("         ");
	
	gotoxy(18, 51);
	
	print(convBuf);	
	
	Disable_Back_Color();
}

/* Return 1 if the filename passed as parameter exists */
char FileExists(void)
{
	char ret;
	
	ret = 0;
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, FindError");
	
	ret = 1;
	
	asm ("FindError:");
	
	return ret;
}

/* Load file into Video Ram B, after build the text list */
void load_file(void)
{
	register unsigned int i;
	char pos = 0, len;
	
	msg_window("Loading file", "Please wait...");
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_find_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	asm ("jr nz, LoadError");
	asm ("ld (_filesize), de");
	
	asm ("push ix");
	asm ("ld de, (_filesize)");
	asm ("ld a, kr_set_load_length");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	
	asm ("push ix");
	asm ("ld hl, (_BufferFile)");
	asm ("ld a, kr_read_file");
	asm ("call.lil prose_kernal");
	asm ("jr nz, LoadError");
	asm ("pop ix");
	
	memset(linbuf, 0, sizeof(linbuf));
	
	linbuf[0] = EOS;
	i = 0;	
	
	while (i <= filesize)
	{
		if (pos < MAXLNLEN - 1)
		{
			linbuf[pos] = BufferFile[i];
			
			if ((linbuf[pos] == EOL) || (i == filesize))
			{
				len = strlen(linbuf);
				
				if (linbuf[pos] == EOL)
					linbuf[len - 1] = EOS;
				else
					linbuf[pos + 1] = EOS;				
				
				purify(linbuf);
					
				tx_ins(p_root, linbuf);
			
				pos = 0;
				memset(linbuf, 0, sizeof(linbuf));
			}
			else
				pos++;
			
			i++;
		}
		else
		{
			purify(linbuf);
			
			tx_ins(p_root, linbuf);
			
			pos = 0;
			memset(linbuf, 0, sizeof(linbuf));
			
			if ((BufferFile[i] == 0x0D) && (BufferFile[i + 1] == 0x0A))
				i += 2;
		}
	}	
	
	asm ("jp f_end");
	
	asm ("LoadError:");
	msg_window("Loading file", "File error!");
	getch();	
	
	asm ("f_end:");
	
	close_msg_window();
}

/* From text list create the file into Video Ram B, after save it */
void save_file(void)
{
	p_line_t p_line = p_root->p_next;
	int slen;	
	
	
	if (UseFile == 0)
	{
		asm ("ld hl, (_NonameFile)");
		asm ("ld (_K_xHL), hl");
		
		msg_window("Please wait, saving", NonameFile);
	}
	else
		msg_window("Saving file", "Please wait...");
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_erase_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld a, kr_create_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");
	asm ("jr nz, SaveError");	
	
	filesize = 0;	
	
	while (p_line != p_root)
	{
		slen = strlen(p_line->p_data);
		
		if (slen > 0)
			memmove(BufferFile + filesize, p_line->p_data, slen);
		
		filesize += slen;
		
		BufferFile[filesize] = 0x0D;
		BufferFile[filesize + 1] = 0x0A;
		
		filesize += 2;
		
		p_line = p_line->p_next;
	}
	
	filesize -= 2;
	
	asm ("push ix");
	asm ("ld hl, (_K_xHL)");
	asm ("ld de, (_BufferFile)");
	asm ("ld bc, (_filesize)");
	asm ("ld a, kr_write_file");
	asm ("call.lil prose_kernal");
	asm ("pop ix");	
	
	asm ("jp s_end");
	
	asm ("SaveError:");
	msg_window("Saving file", "File error!");
	getch();	
	
	asm ("s_end:");
	close_msg_window();
}

/* Reload the file if exist */
void reload_file(void)
{
	if (UseFile == 1)
		if (FileExists() == 1)
		{
			msg_window("Reload file ?", "Y/n");
			getch();
			close_msg_window();
			
			if ((Ascii != 89) && (Ascii != 121))
				return;
			
			sc_fin();
			te_fin();
			
			memset(BufferFile, 0, 1024 * 512);
			
			te_ini();
			sc_ini();
			tx_ini();			
			
			load_file();
			
			cur_row = 0;
			cur_col = 0;
			cur_line = 1;
			cur_char = 1;
			p_curr = p_root->p_next;	
	
			paintall();
	
			sc_fup();
		}
}

/* Draw on screen the message box width 2 lines of text */
void msg_window(char *msg1, char *msg2)
{
	char r, c, len, posx;

	memset(backbuffer, 0, sizeof(backbuffer));
	
	for (r = 0; r < 4; r++)
		for (c = 0; c < SCNCOLS; c++)
			backbuffer[r][c] = scn_phys[r + 23][c];
	
	Enable_Back_Color();
	
	gotoxy(0, 23);
		
	len = strlen(msg1);
	posx = 40 - (len / 2);
	
	print("+==================================]PROTED[====================================+");
	print("|");
	
	for (c = 1; c < posx - 1; c++)
		print(" ");
	
	print(msg1);
	
	for (r = c + len; r < SCNCOLS - 1; r++)
		print(" ");
	
	print("|");
	
	len = strlen(msg2);
	posx = 40 - (len / 2);
	print("|");
	
	for (c = 1; c < posx - 1; c++)
		print(" ");
	
	print(msg2);
	
	for (r = c + len; r < SCNCOLS - 1; r++)
		print(" ");
	
	print("|");
	
	print("+==============================================================================+");
	
	Disable_Back_Color();
}

/* Close the message box */
void close_msg_window(void)
{
	register char r, c;
	
	Disable_Back_Color();
	
	for (r = 0; r < 4; r++)
		for (c = 0; c < SCNCOLS; c++)
			plot_char(c, r + 23, backbuffer[r][c]);
}