#ifndef GAME_C
#define GAME_C

static void apertura(void)
{
	int i;
	
	for(i = 0; i < 4; i++)
	{
		ap[bianco][i][0] = 0;
		ap[bianco][i][1] = 0;
		ap[bianco][i][0] = 0;
		ap[bianco][i][1] = 0;
	}
	
	ap[bianco][0][0]= (scac[e][2]*1000000) + (scac[e][4]*10000) + (e*1000) + (2*100) + (e*10) + 4;
	ap[bianco][0][1]= (scac[b][1]*1000000) + (scac[c][3]*10000) + (b*1000) + (1*100) + (c*10) + 3;
	ap[bianco][1][0]= (scac[d][2]*1000000) + (scac[d][4]*10000) + (d*1000) + (2*100) + (d*10) + 4;
	ap[bianco][1][1]= (scac[g][1]*1000000) + (scac[f][3]*10000) + (g*1000) + (1*100) + (f*10) + 3;
	ap[bianco][2][0]= (scac[g][1]*1000000) + (scac[f][3]*10000) + (g*1000) + (1*100) + (f*10) + 3;
	ap[bianco][2][1]= (scac[d][2]*1000000) + (scac[d][4]*10000) + (d*1000) + (2*100) + (d*10) + 4;
	ap[bianco][3][0]= (scac[g][2]*1000000) + (scac[g][3]*10000) + (g*1000) + (2*100) + (g*10) + 3;
	ap[bianco][3][1]= (scac[f][1]*1000000) + (scac[g][2]*10000) + (f*1000) + (1*100) + (g*10) + 2;
	ap[nero][0][0]=   (scac[d][7]*1000000) + (scac[d][5]*10000) + (d*1000) + (7*100) + (d*10) +5; 
	ap[nero][0][1]=   (scac[e][7]*1000000) + (scac[e][6]*10000) + (e*1000) + (7*100) + (e*10) +6;
	ap[nero][1][0]=   (scac[e][7]*1000000) + (scac[e][5]*10000) + (e*1000) + (7*100) + (e*10) +5;
	ap[nero][1][1]=   (scac[b][8]*1000000) + (scac[c][6]*10000) + (b*1000) + (8*100) + (c*10) +6;
	ap[nero][2][0]=   (scac[d][7]*1000000) + (scac[d][5]*10000) + (d*1000) + (7*100) + (d*10) +5;
	ap[nero][2][1]=   (scac[c][7]*1000000) + (scac[c][6]*10000) + (c*1000) + (7*100) + (c*10) +6;
	ap[nero][3][0]=   (scac[g][7]*1000000) + (scac[g][6]*10000) + (g*1000) + (7*100) + (g*10) +6;
	ap[nero][3][1]=   (scac[g][8]*1000000) + (scac[f][6]*10000) + (g*1000) + (8*100) + (f*10) +6;
}

void raccogli(unsigned long m)
{
	possibili[cont] = m;
	cont++;
	possibili[cont] = 0;
}

char vincitore(void)
{
	int i,j,bian = 0,ner = 0;
	
	for(i = 1; i <= 8; i++)
		for(j = a; j <= h; j++)
			if (scac[i][j] == bre)
				bian = 1;
			else
				if (scac[i][j] == nre)
					ner = 1;
				
	if (ner == 0)
		return 1;
	
	if (bian == 0)
		return 2;
	
	return 0;
}

void inizializza(void)
{
	int i;
	
	mossa_giocata = 0;
	mossa_in_analisi = 0;
	effe = 0;
	prof = 0;
	
	for(i = 0; i < 7; i+=2)
	{
		ramo[i] = 100;
		ramo[i+1] = -100;
	}
}

static void sceglimossa(unsigned long m)
{
	int m_d10_m10 = (m / 10) % 10;
	int m_m10 = m % 10;
	int m_d1M_m100 = (m / 1000000) % 100;
	int m_d100_m10 = (m / 100) % 10;
	int m_d1000_m10 = (m / 1000) % 10;
	
	switch (scac[m_d10_m10][m_m10])
	{
		case nped: effe+=1; break;
		case ncav: effe+=3; break;
		case nalf: effe+=3; break;
		case ndon: effe+=10; break;
		case ntor: effe+=5; break;
		case nre:  effe+=41; break;
		case bped: effe-=1; break;
		case bcav: effe-=3; break;
		case balf: effe-=3; break;
		case bdon: effe-=10; break;
		case btor: effe-=5; break;
		case bre:  effe-=41; break;
	}
	
	if (nmossa < 13 && prof == 0)
	{
		if (col_prof == bianco)
		{
			if ((m_d10_m10 == c || m_d10_m10 == f || m_m10==2 || m_m10==3 )  && m_d1M_m100 == bcav && m_d100_m10 == 1)
				effe+=0.8;
			
			if (m_d100_m10 == 1 && m_d1M_m100 == balf)
				effe+=0.7;
			
			if ((m_d1000_m10 == d || (m/1000)%10==e) && m_d1M_m100 == bped && m_d100_m10 == 2) 
				effe+=0.9;
		}
		else
		{
			if ((m_d10_m10 == c || m_d10_m10 == f || m_m10==6 || m_m10==7 ) && m_d1M_m100 == ncav && m_d100_m10 == 8)
				effe-=0.8;
			
			if ((m/100)%10 == 8 && m_d1M_m100 == nalf)
				effe-=0.7;
			
			if ((m_d1000_m10 == d || m_d1000_m10 == e) && m_d1M_m100 == nped && m_d100_m10 == 7)
				effe-=0.9;
		}
	}
	
	if (nmossa>53 && prof==0 && (m_d1M_m100 == bped || m_d1M_m100 == nped))
	{
		if (col_prof == bianco)
			effe += 0.9;
		else
			effe -= 0.9;
	}
	
	if (m_d1M_m100 == bped && m_m10 == 8)
	{
		scac[m_d10_m10][m_m10]=bdon;
		effe+=9;
	}
	else
		if (m_d1M_m100 == nped && m_m10 == 1)
		{
			scac[m_d10_m10][m_m10]=ndon;
			effe-=9;
		}
		else
		{
			scac[m_d10_m10][m_m10] = m_d1M_m100;
		}
		
	scac[m_d1000_m10][m_d100_m10]=vuoto;
		
	if (prof == livello)
	{
		if ((col_prof==bianco && effe > ramo[prof]) || (col_prof==nero && effe < ramo[prof]))
			ramo[prof]=effe;
	}
	else
	{
		prof++;
		cambiacolore
		calcolamosse(0);
		prof--;
		cambiacolore
		
		if  ((col_prof==bianco && ramo[prof+1]>ramo[prof]) || (col_prof==nero && ramo[prof+1]<ramo[prof]))
		{
			if (prof == 0)
				mossa_giocata = mossa_in_analisi; 
			
			ramo[prof] = ramo[prof+1];
		}
		
		if (col_prof==bianco)
			ramo[prof+1]=100;
		else
			ramo[prof+1]=-100;
	}
	
	if (nmossa<13 && prof==0)
	{
		if (col_prof==bianco)
		{
			if ((m_d10_m10 == c || m_d10_m10 == f || m_m10 == 2 || m_m10==3 )  && m_d1M_m100 == bcav && m_d100_m10 ==1)
				effe-=0.8;
			
			if (m_d100_m10 == 1 && m_d1M_m100 == balf)
				effe-=0.7;
			
			if ((m_d1000_m10 == d || m_d1000_m10 == e) && m_d1M_m100 == bped && m_d100_m10 == 2) 
				effe-=0.9;
		}
		else
		{
			if ((m_d10_m10 == c || m_d10_m10 == f || m_m10==7 || m_m10==6 ) && m_d1M_m100 == ncav && m_d100_m10 == 8)
				effe+=0.8;
			
			if (m_d100_m10 == 8 && m_d1M_m100 == nalf)
				effe+=0.7;
			
			if ((m_d1000_m10 == d || m_d1000_m10 == e) && m_d1M_m100 == nped && m_d100_m10 == 7)
				effe+=0.9;
		}
	}
	
	if (nmossa>53 && prof==0 && (m_d1M_m100 == bped || m_d1M_m100 == nped))
	{
		if (col_prof==bianco)
			effe-=0.9;
		else
			effe+=0.9;
	}
	
	scac[m_d1000_m10][m_d100_m10] = m_d1M_m100;
	scac[m_d10_m10][m_m10]=(m/10000)%100;
	
	switch (scac[m_d10_m10][m_m10])
	{
		case nped: effe-=1; break;
		case ncav: effe-=3; break;
		case nalf: effe-=3; break;
		case ndon: effe-=10; break;
		case ntor: effe-=5; break;
		case nre:  effe-=41; break;
		case bped: effe+=1; break;
		case bcav: effe+=3; break;
		case balf: effe+=3; break;
		case bdon: effe+=10; break;
		case btor: effe+=5; break;
		case bre:  effe+=41; break;
	}
	
	if (m_d1M_m100 == bped && m_m10 == 8)
		effe-=9;
	
	if (m_d1M_m100 == nped && m_m10 == 1)
		effe+=9;
}

void Set_PosScac(void)
{
	int i, j;
	
	for (j = a; j <= h; j++)
		for (i = a; i <= h; i++)
		{
			PosScac[i][j].X = 11 + ((i - 1) * 25);
			PosScac[i][j].Y = 187 - ((j - 1) * 25);
		}
}

void posiniz(void)
{
	int i,j;
	
	for (i = 0; i < 10; i++)
		for (j = 0; j < 10; j++)
		{
			scac[i][j] = vuoto;
			oldscac[i][j] = -1;
		}	
		
	scac[a][1]=btor; scac[b][1]=bcav; scac[c][1]=balf; scac[d][1]=bdon;
	scac[e][1]=bre; scac[f][1]=balf; scac[g][1]=bcav; scac[h][1]=btor;
		
	for (i = a; i <= h; i++)
		scac[i][2] = bped;
	
	scac[a][8]=ntor; scac[b][8]=ncav; scac[c][8]=nalf; scac[d][8]=ndon; scac[e][8]=nre;
	scac[f][8]=nalf; scac[g][8]=ncav; scac[h][8]=ntor;
	
	for (i = a; i <= h; i++)
		scac[i][7] = nped;
	
	Set_PosScac();
}

void stampap(char EraseBack)
{
	int let, num;
	int PosX, PosY;
	char *pImg = NULL, *pBack = NULL;
	unsigned char Val = 0;
	
	for (num = 8; num > 0; num--)
		for(let = 1; let < 9 ; let++)
		{	
			if (scac[let][num] != oldscac[let][num])
			{
				oldscac[let][num] = scac[let][num];
				
				PosX = PosScac[let][num].X + 1;
				PosY = PosScac[let][num].Y + 1;
				
				if (EraseBack)
				{
					PosX--;
					PosY--;
					Val = VideoMem[(PosY << 8) + (PosY << 6) + PosX];
					PosX++;
					PosY++;
				}				
				
				switch (scac[let][num])
				{
					case	vuoto:
						if (EraseBack)
						{
							if (Val == 13)
								pBack = bPiece;
							else
								pBack = wPiece;
							
							Draw_Image(PosX - 1, PosY - 1, 25, 25, pBack);
						}
						
						pImg = NULL;
						break;
						
					case 	bre:
						if (mColore == 0)
							pImg = Bianchi[5];
						else
							pImg = Neri[5];
						break;
						
					case	bdon:
						if (mColore == 0)
							pImg = Bianchi[4];
						else
							pImg = Neri[4];
						break;
						
					case	balf:
						if (mColore == 0)
							pImg = Bianchi[2];
						else
							pImg = Neri[2];						
						break;
						
					case	bcav:
						if (mColore == 0)
							pImg = Bianchi[1];
						else
							pImg = Neri[1];
						break;
						
					case	btor:
						if (mColore == 0)
							pImg = Bianchi[3];
						else
							pImg = Neri[3];
						break;
						
					case	bped:
						if (mColore == 0)
							pImg = Bianchi[0];
						else
							pImg = Neri[0];
						break;
						
					case 	nre:
						if (mColore == 0)
							pImg = Neri[5];							
						else
							pImg = Bianchi[5];
						break;
						
					case	ndon:
						if (mColore == 0)
							pImg = Neri[4];
						else
							pImg = Bianchi[4];
						break;
						
					case	nalf:
						if (mColore == 0)
							pImg = Neri[2];
						else
							pImg = Bianchi[2];
						break;
						
					case	ncav:
						if (mColore == 0)
							pImg = Neri[1];
						else
							pImg = Bianchi[1];
						break;
						
					case	ntor:
						if (mColore == 0)
							pImg = Neri[3];
						else
							pImg = Bianchi[3];
						break;
						
					case	nped:
						if (mColore == 0)
							pImg = Neri[0];
						else
							pImg = Bianchi[0];
						break;
				}
				
				if (pImg != NULL)
				{
					if (EraseBack)
					{
						if (Val == 13)
							pBack = bPiece;
						else
							pBack = wPiece;
							
						Draw_Image(PosX - 1, PosY - 1, 25, 25, pBack);
					}
					
					Draw_Trans_Image(PosX, PosY, 22, 23, pImg, 0);
				}
			}
		}
		
	if (DeleteBack == 0)
		DeleteBack = 1;
}

int mossaimposs(unsigned long m)
{
	int m_d10_m10 = (m / 10) % 10;
	int m_m10 = m % 10;
	int m_d1000_m10 = (m / 1000) % 10;
	int m_d100_m10 = (m / 100) % 10;
	
	if (m_d10_m10 > h || m_d10_m10 < a)
		return 2;
	
	if (m_m10 > 8 || m_m10 < 1)
		return 2;
	
	if ( scac[m_d10_m10][m_m10] <= 6 && scac[m_d10_m10][m_m10] != vuoto && scac[m_d1000_m10][m_d100_m10] <= 6)
		return 2;
	
	if ( scac[m_d10_m10][m_m10] >= 7 && scac[m_d1000_m10][m_d100_m10] >= 7)
		return 2;
	
	if ( scac[m_d1000_m10][m_d100_m10] == bcav || scac[m_d1000_m10][m_d100_m10] == ncav)
		return 1;
	
	if( scac[m_d10_m10][m_m10] != vuoto)
		return 1;
	
	if ( scac[m_d1000_m10][m_d100_m10] == bre || scac[m_d1000_m10][m_d100_m10] == nre)
		return 1;	
		
	return 0;
}

static void calcolamosse(char modo)
{
#define apriciclo la=lp; na=np; do { m=0; m=m+(lp*1000); m=m+(np*100); 
#define completamossa m=m+na; m=m+(la*10);
#define chiudiciclo rit=mossaimposs(m); if (rit!=2) {m=m+(scac[(m/10)%10][m%10] * 10000); m=m+(scac[(m/1000)%10][(m/100)%10] * 1000000); if (prof==0) mossa_in_analisi=m; if (modo==0) sceglimossa(m); else raccogli(m);} } while (rit==0);
#define apriseq la=lp; na=np; m=0; m=m+(lp*1000); m=m+(np*100);
#define chiudiseq if (mossaimposs(m)!=2) {m=m+(scac[(m/10)%10][m%10] * 10000); m=m+(scac[(m/1000)%10][(m/100)%10] * 1000000);if (prof==0) mossa_in_analisi=m; if (modo==0) sceglimossa(m); else raccogli(m);}	
	
	unsigned long m = 0;
	int lp,np,la,na;
	int rit;
	
	for(np = 1; np <= 8; np++)
		for(lp = a; lp <= h; lp++)
		{
			if ((col_prof==bianco && (scac[lp][np] == bdon || scac[lp][np] == bre || scac[lp][np] == btor))  || (col_prof==nero && (scac[lp][np] == ndon || scac[lp][np] == nre || scac[lp][np] == ntor)))
			{
				/*avanti*/ 
				apriciclo 
				++na;
				completamossa
 				chiudiciclo
 				/*indietro*/
 				apriciclo
 				--na; 
				completamossa
 				chiudiciclo
 				/*destra*/
 				apriciclo 
				++la; 
				completamossa 
				chiudiciclo 
				/*sisnistra*/
 				apriciclo 	
				--la; 
				completamossa 
				chiudiciclo
			}
			
			if ((col_prof==bianco && (scac[lp][np] == bdon || scac[lp][np] == bre ||  scac[lp][np] == balf)) || (col_prof==nero && (scac[lp][np] == ndon || scac[lp][np] == nre ||  scac[lp][np] == nalf)))
			{
				/*avanti destra*/
 				apriciclo 
				++na;
 				++la;
 				completamossa 
				chiudiciclo
 				/*avanti sinistra*/ 
				apriciclo
 				++na;
 				--la;
 				completamossa 
				chiudiciclo
 				/*indietro destra*/ 
				apriciclo 
				--na;
 				++la; 
				completamossa 
				chiudiciclo
 				/*indietro sinistra*/ 
				apriciclo 
				--na; 
				--la; 
				completamossa 
				chiudiciclo
			}
			
			if ((col_prof==bianco && scac[lp][np] == bcav) || (col_prof==nero && scac[lp][np] == ncav))
			{
				apriseq 
				na+=2; 
				la++; 
				completamossa 
				chiudiseq 
				apriseq 
				na+=2; 
				la--;
 				completamossa
			 	chiudiseq
 				apriseq 
				na-=2;
 				la++;
 				completamossa
 				chiudiseq
 				apriseq
 				na-=2;
 				la--; 
				completamossa
 				chiudiseq 
				apriseq 
				la+=2; 
				na++;
 				completamossa
 				chiudiseq
 				apriseq
 				la+=2;
 				na--;
 				completamossa 
				chiudiseq 
				apriseq
 				la-=2;
 				na++; 
				completamossa
 				chiudiseq
 				apriseq
 				la-=2;
 				na--;
 				completamossa
 				chiudiseq
			}
			
			if (scac[lp][np] == bped && col_prof==bianco)
			{
				//sequenza pedone bianco
				if (scac[lp][np+1] == vuoto) {
					apriseq
					na++; 
					completamossa 
					chiudiseq
				} 
				if (np==2 && scac[lp][np+1]==vuoto && scac[lp][np+2] ==vuoto)  { 
					apriseq 
					na+=2; 
					completamossa 
					chiudiseq 
				} 
				if (scac[lp+1][np+1]!=vuoto) {
					apriseq 
					la++; 
					na++; 
					completamossa						
					chiudiseq
				} 
				if (scac[lp-1][np+1]!=vuoto)  {
					apriseq 
					na++; 
					la--; 
					completamossa 
					chiudiseq
				}
			}
			
			if (scac[lp][np] == nped && col_prof==nero)
			{
				//sequenza pedone nero
				if (scac[lp][np-1]==vuoto) {
					apriseq 
					na--; 
					completamossa 
					chiudiseq 
				}
				if (np==7 && scac[lp][np-1]==vuoto && scac[lp][np-2]==vuoto)  { 
					apriseq 
					na-=2; 
					completamossa 
					chiudiseq 
				} 
				if (scac[lp+1][np-1]!=vuoto) {
					apriseq 
					la++; 
					na--; 
					completamossa
 					chiudiseq
 				} 
				if (scac[lp-1][np-1]!=vuoto) {
					apriseq 
					na--; 
					la--; 
					completamossa 
					chiudiseq
				} 
			}
		}
		
#undef apriciclo
#undef chiudiciclo
#undef completamossa
#undef apriseq
#undef chiudiseq	
}

void modifica(unsigned long m)
{
	int m_d10_m10 = (m / 10) % 10;
	int m_m10 = m % 10;
	
	scac[m_d10_m10][m_m10] = (m/1000000)%100;
	scac[(m/1000)%10][(m/100)%10] = vuoto;
	
	if (scac[m_d10_m10][m_m10] == bped && m_m10 == 8)
		scac[m_d10_m10][m_m10] = bdon;
	
	if (scac[m_d10_m10][m_m10] == nped && m_m10 == 1)
		scac[m_d10_m10][m_m10] = ndon;
}

unsigned long acquisisci(void)
{
	long m,lp,np,la,na;
	char s[4], *pPlay;
	
	Fill_Rectangle(218, 75, 96, 10, 0);
	
	if (PlayerColor == 0)
		Draw_Image(245, 75, 42, 10, wPlay);
	else
		Draw_Image(243, 75, 48, 10, bPlay);
	
	do
	{
		Crea_Mossa();
	
		if (!chAbort)
		{
			s[0] = Mossa1[0];
			s[1] = Mossa1[1];
			s[2] = Mossa2[0];
			s[3] = Mossa2[1];
		
			m=0;
			lp=(long)(s[0]-'a'+1);
			np=(long)(s[1]-'0');
			la=(long)(s[2]-'a'+1);
			na=(long)(s[3]-'0');
			m=m+(lp*1000);
			m=m+(np*100);
			m=m+(la*10);
			m=m+na;
			m=m+(scac[lp][np]*1000000);
			m=m+(scac[la][na]*10000);
		}
		else
			return 0;
	}
	while (controllo(m) == 0);
	
	return m;
}

void apri(int colore_utente)
{
	int i;
	int casuale;
	
	srand(5005 + (rand() * 1000));
	srand(rand() * rand());
	
	casuale = rand() % 4;
	
	for(i = 0; i < 2; i++)
		if (colore_utente == bianco)
		{
			stampap(DeleteBack);
			
			if (i == 1)
				Play_Raw_Audio(&Chs2);
			
			modifica(acquisisci());
			
			if (chAbort)
				return;
			
			stampap(DeleteBack);
			
			Play_Raw_Audio(&Chs1);
			
			modifica(ap[nero][casuale][i]);
			
			if (i == 1)
			{
				stampap(DeleteBack);
				
				Play_Raw_Audio(&Chs2);
			}
		}
		else
		{
			modifica(ap[bianco][casuale][i]);
			stampap(DeleteBack);
			modifica(acquisisci());
			stampap(DeleteBack);
		}
}

char controllo(unsigned long m)
{
	int i = 0;
	char superato = 0;
	
	cont = 0;
	calcolamosse(1);
	
	while (possibili[i] != 0)
		if (m == possibili[i++])
		{
			superato = 1;
			break;
		}
		
	return superato;
}

#endif
