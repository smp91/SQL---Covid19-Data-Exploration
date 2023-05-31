-- Covid19 Data Exploration

SELECT * FROM CovidDeaths

SELECT * FROM CovidVaccinations


-- Selecting the important columns that we are going to be using from CovidDeaths Table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY location, date



--Checking Data type of the important columns that we are going to be using

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths' 
AND COLUMN_NAME IN ('location', 'date', 'total_cases', 'new_cases', 'total_deaths', 'population')



-- Changing the data type of total_cases and total_deaths from nvarchar to float

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT



-- Total Cases vs Population
-- Percentage of population that got Covid in Canada

SELECT location, date, population, total_cases, ROUND((total_cases/population)*100, 4) AS PercentPopulationInfected
FROM CovidDeaths
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY location, date



-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract Covid in Canada

SELECT location, date, total_cases, total_deaths, ROUND(((CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT)))*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY location, date



-- Countires with highest infection rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(ROUND((total_cases/population)*100, 4)) AS MaxPercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MaxPercentPopulationInfected DESC



-- Countries with highest death count per Population

SELECT location, population, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC



-- Continents with highest death count

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Death Percentage per Day

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date



-- Global Death Percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL



-- Total Population vs Vaccination

-- Joining the Two tables on Date and Location

SELECT * FROM CovidDeaths AS death
JOIN CovidVaccinations AS vacc
ON death.location = vacc.location AND death.date = vacc.date


-- Total population vs vaccination and Rolling People Vaccinated who have received at least one Covid Vaccine by Date

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date



-- Using CTE to Calculate the Percentage of Rolling People Vaccinated who have received at least one Covid Vaccine by Date

WITH PopulationVsVaccination
AS (
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
-- ORDER BY death.location, death.date
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopulationVsVaccination



-- Using TEMP Table to calculate the Percentage of Rolling People Vaccinated who have received at least one Covid Vaccine by Date

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
-- ORDER BY death.location, death.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated



-- Create View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS FLOAT)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vacc
ON death.location = vacc.location AND death.date = vacc.date
WHERE death.continent IS NOT NULL
-- ORDER BY death.location, death.date

SELECT * FROM PercentPopulationVaccinated



