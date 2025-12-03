library ieee;
use ieee.std_logic_1164.all;
-- Inclusion du paquetage de constantes personnalisées (ex: DATA_W)
use work.constants_pkg.all;

-- =======================================================================
-- ENTITÉ : instruction_reg
-- DESCRIPTION : Registre d'instruction à deux étages capable de gérer
-- des instructions sur 8 bits ou 16 bits. Il capture les données du bus
-- et "découpe" les champs (opcode, registres) pour l'unité de contrôle.
-- =======================================================================
entity instruction_reg is
  port (
    -- Signaux globaux
    clk      : in  std_logic; -- Horloge système
    rst_n    : in  std_logic; -- Réinitialisation asynchrone active bas

    -- Signaux de contrôle (venant de la Control Unit)
    ir_load  : in  std_logic; -- Active le chargement du 1er octet (Opcode/Dest)
    imm_load : in  std_logic; -- Active le chargement du 2ème octet (Immédiat/Source)

    -- Entrée de données
    bus_in   : in  std_logic_vector(DATA_W-1 downto 0); -- Bus de données principal (8 bits)

    -- Sorties décodées (Bit Slicing)
    opcode   : out std_logic_vector(3 downto 0); -- Opcode (4 bits de poids fort du 1er octet)
    rd_sel   : out std_logic_vector(2 downto 0); -- Sélecteur Registre Destination (bits 3-1 du 1er octet)
    rs_sel   : out std_logic_vector(2 downto 0); -- Sélecteur Registre Source (bits 2-0 du 2ème octet!)
    imm      : out std_logic_vector(DATA_W-1 downto 0); -- Valeur immédiate complète (2ème octet entier)

    -- Sorties de débogage (optionnelles, pour voir le contenu brut)
    ir_byte  : out std_logic_vector(DATA_W-1 downto 0);
    imm_byte : out std_logic_vector(DATA_W-1 downto 0)
  );
end entity;

architecture rtl of instruction_reg is
  -- Registres internes pour stocker les deux parties potentielles de l'instruction
  signal ir_reg  : std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- Stocke le 1er octet
  signal imm_reg : std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- Stocke le 2ème octet
begin

  -- =====================================================================
  -- PROCESSUS SÉQUENTIEL : Capture des données du bus
  -- =====================================================================
  process(clk, rst_n)
  begin
    -- Réinitialisation asynchrone
    if rst_n='0' then
      ir_reg  <= (others=>'0');
      imm_reg <= (others=>'0');
    -- Logique synchrone sur front montant d'horloge
    elsif rising_edge(clk) then
      -- Si l'ordre de charger le premier octet est donné
      if ir_load='1' then
        ir_reg <= bus_in;
      end if;
      -- Si l'ordre de charger le deuxième octet (immédiat/source) est donné
      if imm_load='1' then
        imm_reg <= bus_in;
      end if;
    end if;
  end process;

  -- =====================================================================
  -- LOGIQUE COMBINATOIRE : Décodage et affectation des sorties (Bit Slicing)
  -- =====================================================================
  -- Extraction de l'Opcode (bits [7:4] du 1er registre)
  opcode <= ir_reg(7 downto 4);

  -- Extraction du registre de destination (bits [3:1] du 1er registre)
  rd_sel <= ir_reg(3 downto 1);

  -- ATTENTION : Extraction du registre SOURCE (bits [2:0] du 2ème registre)
  rs_sel <= imm_reg(2 downto 0);

  -- Le deuxième registre entier peut servir de valeur immédiate
  imm    <= imm_reg;

  -- Connexion des registres internes aux sorties de debug
  ir_byte  <= ir_reg;
  imm_byte <= imm_reg;

end architecture;
