SELECT *
FROM PorfolioProject..CovidDeaths$
ORDER BY 3,4

--Now that I know I have successfully imported my data I am  going to pull up data about the cases with a focus on South Africa 

SELECT location, date,total_cases,total_deaths
FROM PorfolioProject..CovidDeaths$
WHERE location= 'South Africa'
ORDER BY 1,2

--percentage of deaths

SELECT location, date,total_cases,total_deaths, (total_deaths/total_cases)*100 death_percentage
FROM PorfolioProject..CovidDeaths$
WHERE location= 'South Africa'
ORDER BY 1,2

--this shows the likelihood of dying if you have contracted covid and it was relatively low and gradually increased in 2021 however was still below 5%
--Total_cases vs population 

SELECT location, date,total_cases, population, (total_cases/population)*100 population_percentage
FROM PorfolioProject..CovidDeaths$
WHERE location= 'South Africa'
ORDER BY 1,2

-- this shows the percentage of cases relative to the population.It gradually increase to 2% throughout 2020 and into the first quarter of 2021

SELECT location,population, MAX(total_cases) highest_infection, MAX((total_cases/population))*100 Percentage_population_infected
FROM PorfolioProject..CovidDeaths$
--WHERE location= 'South Africa'
GROUP BY location, population
ORDER BY 4 DESC 

--we can see that compared to other countries South Africa has a low infection rate but still lies in the upper half in ranking

SELECT continent, MAX(cast(total_deaths as int)) highest_deaths
FROM PorfolioProject..CovidDeaths$
--WHERE location= 'South Africa'
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC 

-- Overall between 2020 and the first 4 months of 2021 Africa had the second lowest number of deaths dispite have one of the largest populations 

--GLOBAL numbers

  SELECT SUM(new_cases) total_cases,SUM(cast(new_deaths as int)) total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 death_percentage
  FROM PorfolioProject..CovidDeaths$
  --WHERE location= 'South Africa'
  WHERE continent is not null
  --GROUP BY date
  ORDER BY 1,2

--Globally the percentage of total deaths is around 2%

--Looking at Total population versus vaccination 

SELECT deaths.continent,deaths.location,deaths.date,deaths.population, vac.new_vaccinations, SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location,deaths.date) rolling_people_vaccination
FROM PorfolioProject..Covidvaccinatons$ vac
Join PorfolioProject..CovidDeaths$ deaths
   ON deaths.date=vac.date 
   and deaths.location=vac.location
WHERE deaths.continent is not null  and  deaths.population is not null
Order by 2,3

-- Using CTE

WITH PopvVac (continent, location,date,population ,new_vaccinations,rolling_people_vaccination)
as
(SELECT deaths.continent,deaths.location,deaths.date,deaths.population, vac.new_vaccinations, SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location,deaths.date) rolling_people_vaccination
FROM PorfolioProject..Covidvaccinatons$ vac
Join PorfolioProject..CovidDeaths$ deaths
   ON deaths.date=vac.date 
   and deaths.location=vac.location
WHERE deaths.continent is not null  and  deaths.population is not null)

Select *, (rolling_people_vaccination/population)*100
FROM PopvVac

--Temp table 

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vaccination numeric)

Insert into #PercentPopulationVaccinated
SELECT deaths.continent,deaths.location,deaths.date,deaths.population, vac.new_vaccinations, SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location,deaths.date) rolling_people_vaccination
FROM PorfolioProject..Covidvaccinatons$ vac
Join PorfolioProject..CovidDeaths$ deaths
   ON deaths.date=vac.date 
   and deaths.location=vac.location
--WHERE deaths.continent is not null  and  deaths.population is not null
--  Order by 2,3

Select *, (rolling_people_vaccination/population)*100
FROM #PercentPopulationVaccinated


--Creating view to store data for later 

Create View PercentPopulationVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as rolling_people_vaccination
--, (rolling_people_vaccination/population)*100
From PortfolioProject..CovidVaccinations vac
Join PortfolioProject..CovidDeaths$ deaths
	ON deaths.date=vac.date 
        and deaths.location=vac.location

WHERE deaths.continent is not null 
