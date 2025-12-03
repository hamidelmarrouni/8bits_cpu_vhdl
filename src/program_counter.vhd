library ieee;
use ieee.std_logic_1164.all;
-- Inclusion de numeric_std pour les opérations arithmétiques (signées/non-signées)
use ieee.numeric_std.all;
use work.constants_pkg.all;

-- =======================================================================
-- ENTITÉ : program_counter
-- DESCRIPTION : Compteur de programme générique. Il maintient l'adresse
-- courante et la met à jour selon des priorités : Reset > Saut Absolu >
-- Saut Relatif > Incrémentation.
-- =======================================================================
entity program_counter is
  generic (
    ADDR_W_G : natural := ADDR_W -- Largeur générique de l'adresse
  );
  port (
    -- Signaux globaux
    clk         : in  std_logic;
    rst_n       : in  std_logic;

    -- Signaux de contrôle de mise à jour (venant de la Control Unit)
    pc_inc      : in  std_logic; -- Ordre d'incrémentation simple (+1)
    pc_load     : in  std_logic; -- Ordre de saut absolu (JUMP)
    do_branch   : in  std_logic; -- Ordre de saut relatif (BRANCH/BNE/BEQ)

    -- Entrées de données pour les sauts
    pc_load_val : in  std_logic_vector(ADDR_W_G-1 downto 0); -- Adresse cible pour le saut absolu
    off8        : in  std_logic_vector(7 downto 0);          -- Offset signé de 8 bits pour le saut relatif

    -- Sortie
    pc_addr     : out std_logic_vector(ADDR_W_G-1 downto 0)  -- Adresse actuelle vers la mémoire
  );
end entity;

architecture rtl of program_counter is
  -- Registre interne qui stocke la valeur actuelle du PC
  signal pc_reg    : std_logic_vector(ADDR_W_G-1 downto 0) := (others => '0');
  -- Signal intermédiaire pour l'offset étendu en signe
  signal off8_sext : signed(ADDR_W_G-1 downto 0);
begin

  -- =====================================================================
  -- EXTENSION DE SIGNE (Logique Combinatoire)
  -- =====================================================================
  -- Convertit l'offset de 8 bits (off8) en un type signé, puis l'étend
  -- à la largeur totale du bus d'adresse (ADDR_W_G) en préservant le signe.
  -- Nécessaire pour permettre des sauts en arrière (valeurs négatives).
  off8_sext <= resize(signed(off8), ADDR_W_G);

  -- =====================================================================
  -- PROCESSUS SÉQUENTIEL : Mise à jour du PC avec priorités
  -- =====================================================================
  process(clk, rst_n)
  begin
    -- Priorité 1 (Absolue) : Réinitialisation asynchrone
    if rst_n = '0' then
      pc_reg <= (others => '0');

    -- Logique synchrone sur front montant
    elsif rising_edge(clk) then

      -- Priorité 2 : Saut Absolu (JUMP)
      -- Si pc_load est actif, on charge directement la nouvelle adresse.
      if pc_load = '1' then
        pc_reg <= pc_load_val;

      -- Priorité 3 : Saut Relatif (BRANCH)
      -- Si do_branch est actif, on ajoute l'offset signé à l'adresse actuelle.
      -- Utilisation de 'signed' pour gérer les additions positives ou négatives.
      elsif do_branch = '1' then
        pc_reg <= std_logic_vector( signed(pc_reg) + off8_sext );

      -- Priorité 4 (Par défaut) : Incrémentation
      -- Si pc_inc est actif, on avance à l'instruction suivante (+1).
      -- Utilisation de 'unsigned' pour une simple incrémentation.
      elsif pc_inc = '1' then
        pc_reg <= std_logic_vector( unsigned(pc_reg) + 1 );
      end if;
      -- Note : Si aucun signal n'est actif, le PC garde sa valeur (comportement par défaut du latch).
    end if;
  end process;

  -- =====================================================================
  -- SORTIE
  -- =====================================================================
  -- Connecte le registre interne à la sortie du module
  pc_addr <= pc_reg;

end architecture;
