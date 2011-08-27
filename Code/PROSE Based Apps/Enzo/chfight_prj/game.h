#ifndef GAME_H
#define GAME_H

#define a 				1
#define b 				2
#define c 				3
#define d 				4
#define e 				5
#define f 				6
#define g 				7
#define h 				8

#define bianco 			0
#define nero 			1

#define vuoto 			0
#define bre 			1
#define bdon 			2
#define balf 			3
#define bcav 			4
#define btor 			5
#define bped 			6
#define nre 			7
#define ndon 			8
#define nalf 			9
#define ncav 			10
#define ntor 			11
#define nped 			12

#define cambiacolore if (col_prof==bianco) col_prof=nero; else col_prof=bianco;

typedef struct {
	int X, Y;
} XYPos;

unsigned long mossa_giocata = 0, mossa_in_analisi = 0;
long scac[10][10], oldscac[10][10];
XYPos PosScac[10][10];
int col_prof = bianco;
long nmossa = 0;
float effe = 0;
long prof = 0;
long livello = 4;
float ramo[7];
unsigned long possibili[100];
unsigned long ap[2][4][2];
long cont = 0;

static void apertura(void);
void raccogli(unsigned long m);
char vincitore(void);
void inizializza(void);
static void sceglimossa(unsigned long m);
int mossaimposs(unsigned long m);
static void calcolamosse(char modo);
void posiniz(void);
void stampap(char EraseBack);
void modifica(unsigned long m);
unsigned long acquisisci(void);
void apri(int colore_utente);
char controllo(unsigned long m);

#endif
